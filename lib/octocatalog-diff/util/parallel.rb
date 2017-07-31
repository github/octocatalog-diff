# frozen_string_literal: true

# A class to parallelize process executation.
# This is a utility class to execute tasks in parallel, with our own forking implementation
# that passes through logs and reliably handles errors. If parallel processing has been disabled,
# this instead executes the tasks serially, but provides the same API as the parallel tasks.

require 'stringio'

module OctocatalogDiff
  module Util
    class Parallel
      # This exception is called for a task that didn't complete.
      class IncompleteTask < RuntimeError; end

      # --------------------------------------
      # This class represents a parallel task. It requires a method reference, which will be executed with
      # any supplied arguments. It can optionally take a text description and a validator function.
      # --------------------------------------
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

      # --------------------------------------
      # This class represents the result from a parallel task. The status is set to true (success), false (error),
      # or nil (task was killed before it could complete). The exception (for failure) and output object (for success)
      # are readable attributes. The validity of the results, determined by executing the 'validate' method of the Task,
      # is available to be set and fetched.
      # --------------------------------------
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

      # --------------------------------------
      # Static methods in the class
      # --------------------------------------

      # Entry point for parallel processing. By default this will perform parallel processing,
      # but it will also accept an option to do serial processing instead.
      # @param task_array [Array<Parallel::Task>] Tasks to run
      # @param logger [Logger] Optional logger object
      # @param parallelized [Boolean] True for parallel processing, false for serial processing
      # @param raise_exception [Boolean] True to raise exception immediately if one occurs; false to return exception in results
      # @return [Array<Parallel::Result>] Parallel results (same order as tasks)
      def self.run_tasks(task_array, logger = nil, parallelized = true, raise_exception = false)
        # Create a throwaway logger object if one is not given
        logger ||= Logger.new(StringIO.new)

        # Validate input - we need an array of OctocatalogDiff::Util::Parallel::Task. If the array is empty then
        # return an empty array right away.
        raise ArgumentError, "run_tasks() argument must be array, not #{task_array.class}" unless task_array.is_a?(Array)
        return [] if task_array.empty?

        invalid_inputs = task_array.reject { |task| task.is_a?(OctocatalogDiff::Util::Parallel::Task) }
        if invalid_inputs.any?
          ele = invalid_inputs.first
          raise ArgumentError, "Element #{ele.inspect} must be a OctocatalogDiff::Util::Parallel::Task, not a #{ele.class}"
        end

        # Initialize the result array. For now all entries in the array indicate that the task was killed.
        # Actual statuses will replace this initial status. If the initial status wasn't replaced, then indeed,
        # the task was killed.
        result = task_array.map { |x| Result.new(exception: IncompleteTask.new('Killed'), args: x.args) }
        logger.debug "Initialized parallel task result array: size=#{result.size}"

        # Execute as per the requested method (serial or parallel) and handle results.
        exception = parallelized ? run_tasks_parallel(result, task_array, logger) : run_tasks_serial(result, task_array, logger)
        raise exception if exception && raise_exception
        result
      end

      # Utility method! Not intended to be called from outside this class.
      # ---
      # Use a forking strategy to run tasks in parallel. Each task in the array is forked in a child
      # process, and when that task completes it writes its result (OctocatalogDiff::Util::Parallel::Result)
      # into a serialized data file. Once children are forked this method waits for their return, deserializing
      # the output from each data file and updating the `result` array with actual results.
      # @param result [Array<OctocatalogDiff::Util::Parallel::Result>] Parallel task results
      # @param task_array [Array<OctocatalogDiff::Util::Parallel::Task>] Tasks to perform
      # @param logger [Logger] Logger
      # @return [Exception] First exception encountered by a child process; returns nil if no exceptions encountered.
      def self.run_tasks_parallel(result, task_array, logger)
        pidmap = {}
        ipc_tempdir = Dir.mktmpdir('ocd-ipc-')

        # Child process forking
        task_array.each_with_index do |task, index|
          # simplecov doesn't see this because it's forked
          # :nocov:
          this_pid = fork do
            task_result = execute_task(task, logger)
            File.open(File.join(ipc_tempdir, "#{Process.pid}.dat"), 'w') { |f| f.write Marshal.dump(task_result) }
            Kernel.exit! 0 # Kernel.exit! avoids at_exit from parents being triggered by children exiting
          end
          # :nocov:

          pidmap[this_pid] = { index: index, start_time: Time.now }
          logger.debug "Launched pid=#{this_pid} for index=#{index}"
          logger.reopen if logger.respond_to?(:reopen)
        end

        # Waiting for children and handling results
        while pidmap.any?
          this_pid, exit_obj = Process.wait2(0)
          next unless this_pid && pidmap.key?(this_pid)
          index = pidmap[this_pid][:index]
          exitstatus = exit_obj.exitstatus
          raise "PID=#{this_pid} exited abnormally: #{exit_obj.inspect}" if exitstatus.nil?
          raise "PID=#{this_pid} exited with status #{exitstatus}" unless exitstatus.zero?

          input = File.read(File.join(ipc_tempdir, "#{this_pid}.dat"))
          result[index] = Marshal.load(input) # rubocop:disable Security/MarshalLoad
          time_delta = Time.now - pidmap[this_pid][:start_time]
          pidmap.delete(this_pid)

          logger.debug "PID=#{this_pid} completed in #{time_delta} seconds, #{input.length} bytes"

          next if result[index].status
          return result[index].exception
        end

        logger.debug 'All child processes completed with no exceptions raised'

      # Cleanup: Kill any child processes that are still running, and clean the temporary directory
      # where data files were stored.
      ensure
        pidmap.each do |pid, _pid_data|
          begin
            Process.kill('TERM', pid)
          rescue Errno::ESRCH # rubocop:disable Lint/HandleExceptions
            # If the process doesn't exist, that's fine.
          end
        end

        retries = 0
        while File.directory?(ipc_tempdir) && retries < 10
          retries += 1
          begin
            FileUtils.remove_entry_secure ipc_tempdir
          rescue Errno::ENOTEMPTY, Errno::ENOENT # rubocop:disable Lint/HandleExceptions
            # Errno::ENOTEMPTY will trigger a retry because the directory exists
            # Errno::ENOENT will break the loop because the directory won't exist next time it's checked
          end
        end
      end

      # Utility method! Not intended to be called from outside this class.
      # ---
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

      # Utility method! Not intended to be called from outside this class.
      # ---
      # Process a single task. Called by run_tasks_parallel / run_tasks_serial.
      # This method will report all exceptions in the OctocatalogDiff::Util::Parallel::Result object
      # itself, and not raise them.
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
          # Immediately return without running the validation, since this already failed.
          return Result.new(exception: exc, status: false, args: task.args)
        end

        begin
          if task.validate(output, logger)
            logger.debug("Success #{task.description}")
          else
            # Preferably the validator method raised its own exception. However if it
            # simply returned false, raise our own exception here.
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
