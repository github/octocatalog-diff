# frozen_string_literal: true

# Parallelize process executation.

require 'stringio'
require 'yaml'

module OctocatalogDiff
  module Util
    # This is a utility class to execute tasks in parallel, using the 'parallel' gem.
    # If parallel processing has been disabled, this instead executes the tasks serially,
    # but provides the same API as the parallel tasks.
    class Parallel
      BLOCK_SIZE = 1024 * 16

      # This class is called for a task that didn't complete.
      class IncompleteTask < RuntimeError; end

      # This class represents a parallel task. It requires a method reference, which will be executed with
      # any supplied arguments. It can optionally take a text description and a validator function.
      class Task
        attr_reader :description
        attr_accessor :args

        def initialize(opts = {})
          @method = opts.fetch(:method)
          @args = opts.fetch(:args, {})
          @description = opts[:description] || @method.name
          @validator = opts[:validator]
          @validator_args = opts[:validator_args] || {}
        end

        def execute(logger = Logger.new(StringIO.new))
          @method.call(@args, logger)
        end

        def validate(result, logger = Logger.new(StringIO.new))
          return true if @validator.nil?
          @validator.call(result, logger, @validator_args)
        end
      end

      # This class represents the result from a parallel task. The status is set to true (success), false (error),
      # or nil (task was killed before it could complete). The exception (for failure) and output object (for success)
      # are readable attributes. The validity of the results, determined by executing the 'validate' method of the Task,
      # is available to be set and fetched.
      class Result
        attr_reader :output, :args
        attr_accessor :status, :exception

        def initialize(opts = {})
          @status = opts[:status]
          @exception = opts[:exception]
          @output = opts[:output]
          @args = opts.fetch(:args, {})
        end
      end

      # Entry point for parallel processing. By default this will perform parallel processing,
      # but it will also accept an option to do serial processing instead.
      # @param task_array [Array<Parallel::Task>] Tasks to run
      # @param logger [Logger] Optional logger object
      # @param parallelized [Boolean] True for parallel processing, false for serial processing
      # @return [Array<Parallel::Result>] Parallel results (same order as tasks)
      #
      # Note: Parallelization throws intermittent errors under travis CI, so it will be disabled by
      # default for integration tests.
      def self.run_tasks(task_array, logger = nil, parallelized = true, raise_exception = true)
        # Create a throwaway logger object if one is not given
        logger ||= Logger.new(StringIO.new)

        # Validate input - we need an array. If the array is empty then return an empty array right away.
        raise ArgumentError, "run_tasks() argument must be array, not #{task_array.class}" unless task_array.is_a?(Array)
        return [] if task_array.empty?

        # Make sure each element in the array is a OctocatalogDiff::Util::Parallel::Task
        task_array.each do |x|
          next if x.is_a?(OctocatalogDiff::Util::Parallel::Task)
          raise ArgumentError, "Element #{x.inspect} must be a OctocatalogDiff::Util::Parallel::Task, not a #{x.class}"
        end

        result = task_array.map do |x|
          Result.new(exception: IncompleteTask.new('Killed'), args: x.args)
        end
        logger.debug "Initialized parallel task result array: size=#{result.size}"

        exception = if parallelized
          run_tasks_parallel(result, task_array, logger)
        else
          run_tasks_serial(result, task_array, logger)
        end

        raise exception if exception && raise_exception
        result
      end

      # Use the parallel gem to run each task in the task array. Under the hood this is forking a process for
      # each task, and serializing/deserializing the arguments and the outputs.
      # @param result [Array<OctocatalogDiff::Util::Parallel::Result>] Parallel task results
      # @param task_array [Array<OctocatalogDiff::Util::Parallel::Task>] Tasks to perform
      # @param logger [Logger] Logger
      def self.run_tasks_parallel(result, task_array, logger)
        pidmap = {}

        task_array.each_with_index do |task, index|
          reader, writer = IO.pipe

          # simplecov doesn't see this because it's forked
          # :nocov:
          this_pid = fork do
            reader.close
            logger.reopen if logger.respond_to?(:reopen)
            task_result = execute_task(task, logger)
            writer.write YAML.dump(task_result)
            writer.close
            logger.close
            exit 0
          end
          # :nocov:

          pidmap[this_pid] = { reader: reader, index: index, start_time: Time.now, result: [] }
          writer.close
          logger.debug "Launched pid=#{this_pid} for index=#{index}"
          logger.reopen
        end

        while pidmap.any?
          # Read from all pipes
          pidmap.each do |_this_pid, obj|
            begin
              buf = obj[:reader].read_nonblock(BLOCK_SIZE, buf)
              obj[:result] << buf if buf
            rescue IO::EAGAINWaitReadable, EOFError, Errno::EAGAIN # rubocop:disable Lint/ShadowedException
              next
            end
          end

          # Any exits?
          this_pid, exit_obj = Process.wait2(0, Process::WNOHANG)
          unless this_pid && pidmap.key?(this_pid)
            sleep 0.1
            next
          end

          index = pidmap[this_pid][:index]
          exitstatus = exit_obj.exitstatus
          raise "PID=#{this_pid} exited abnormally: #{exit_obj.inspect}" if exitstatus.nil?
          raise "PID=#{this_pid} exited with status #{exitstatus}" unless exitstatus.zero?

          begin
            buf = pidmap[this_pid][:reader].read_nonblock(BLOCK_SIZE, buf)
            pidmap[this_pid][:result] << buf if buf
          rescue IO::EAGAINWaitReadable, EOFError, Errno::EAGAIN # rubocop:disable Lint/ShadowedException
            pidmap[this_pid][:reader].close
          end

          input = pidmap[this_pid][:result].join('')
          logger.debug "PID=#{this_pid} completed in #{Time.now - pidmap[this_pid][:start_time]} seconds, #{input.length} bytes"

          pidmap.delete(this_pid)

          result[index] = YAML.load(input)

          next if result[index].status
          return result[index].exception
        end
        nil
      ensure
        pidmap.each do |pid, pid_data|
          pid_data[:reader].close
          begin
            Process.kill('TERM', pid)
          rescue Errno::ESRCH # rubocop:disable Lint/HandleExceptions
            # If the process doesn't exist, that's fine.
          end
        end
      end

      # Perform the tasks in serial.
      # @param result [Array<OctocatalogDiff::Util::Parallel::Result>] Parallel task results
      # @param task_array [Array<OctocatalogDiff::Util::Parallel::Task>] Tasks to perform
      # @param logger [Logger] Logger
      def self.run_tasks_serial(result, task_array, logger)
        # Perform the tasks 1 by 1 - each successful task will replace an element in the 'result' array,
        # whereas a failed task will replace the current element with an exception, and all later tasks
        # will not be replaced (thereby being populated with the cancellation error).
        task_array.each_with_index do |ele, task_counter|
          result[task_counter] = execute_task(ele, logger)
          next if result[task_counter].status
          return result[task_counter].exception
        end
        nil
      end

      # Process a single task.
      # @param task [OctocatalogDiff::Util::Parallel::Task] Task object
      # @param logger [Logger] Logger
      # @return [OctocatalogDiff::Util::Parallel::Result] Parallel task result
      def self.execute_task(task, logger)
        begin
          logger.debug("Begin #{task.description}")
          output = task.execute(logger)
          result = Result.new(output: output, status: true, args: task.args)
        rescue => exc
          logger.debug("Failed #{task.description}: #{exc.class} #{exc.message}")
          return Result.new(exception: exc, status: false, args: task.args)
        end

        begin
          if task.validate(output, logger)
            logger.debug("Success #{task.description}")
          else
            raise "Failed #{task.description} validation (unspecified error)"
          end
        rescue => exc
          logger.warn("Failed #{task.description} validation: #{exc.class} #{exc.message}")
          result.status = false
          result.exception = exc
        end

        result
      end
    end
  end
end
