# frozen_string_literal: true

# Helper to use the 'parallel' gem to perform tasks

require 'parallel'
require 'stringio'

module OctocatalogDiff
  module Util
    # This is a utility class to execute tasks in parallel, using the 'parallel' gem.
    # If parallel processing has been disabled, this instead executes the tasks serially,
    # but provides the same API as the parallel tasks.
    class Parallel
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
        end

        def execute(logger = Logger.new(StringIO.new))
          @method.call(@args, logger)
        end

        def validate(result, logger = Logger.new(StringIO.new))
          return true if @validator.nil?
          @validator.call(result, logger)
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
      def self.run_tasks(task_array, logger = nil, parallelized = true)
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

        # Actually do the processing - choose here between parallel and serial
        parallelized ? run_tasks_parallel(task_array, logger) : run_tasks_serial(task_array, logger)
      end

      # Use the parallel gem to run each task in the task array. Under the hood this is forking a process for
      # each task, and serializing/deserializing the arguments and the outputs.
      # @param task_array [Array<OctocatalogDiff::Util::Parallel::Task>] Tasks to perform
      # @param logger [Logger] Logger
      # @return [Array<OctocatalogDiff::Util::Parallel::Result>] Parallel task results
      def self.run_tasks_parallel(task_array, logger)
        # Create an empty array of results. The status is nil and the exception is pre-populated. If the code
        # runs successfully and doesn't get killed, all of these default values will be overwritten. If the code
        # gets killed before the task finishes, this exception will remain.
        result = task_array.map do |x|
          Result.new(exception: ::Parallel::Kill.new('Killed'), args: x.args)
        end
        logger.debug "Initialized parallel task result array: size=#{result.size}"

        # Do parallel processing
        ::Parallel.each(task_array,
                        finish: lambda do |item, i, parallel_result|
                          # Set the result array element to the result
                          result[i] = parallel_result

                          # Kill all other parallel tasks if this task failed by throwing an exception
                          raise ::Parallel::Kill unless parallel_result.exception.nil?

                          # Run the validator to determine if the result is in fact valid. The validator
                          # returns true or false. If true, set the 'valid' attribute in the result. If
                          # false, kill all other parallel tasks.
                          if item.validate(parallel_result.output, logger)
                            logger.debug("Success #{item.description}")
                          else
                            logger.warn("Failed #{item.description}")
                            result[i].status = false
                            raise ::Parallel::Kill
                          end
                        end) do |ele|
          # simplecov does not detect that this code runs because it's forked, but this is
          # tested extensively in the parallel_spec.rb spec file.
          # :nocov:
          begin
            logger.debug("Begin #{ele.description}")
            output = ele.execute(logger)
            logger.debug("Success #{ele.description}")
            Result.new(output: output, status: true, args: ele.args)
          rescue => exc
            logger.debug("Failed #{ele.description}: #{exc.class} #{exc.message}")
            Result.new(exception: exc, status: false, args: ele.args)
          end
          # :nocov:
        end

        # Return result
        result
      end

      # Perform the tasks in serial.
      # @param task_array [Array<OctocatalogDiff::Util::Parallel::Task>] Tasks to perform
      # @param logger [Logger] Logger
      # @return [Array<OctocatalogDiff::Util::Parallel::Result>] Parallel task results
      def self.run_tasks_serial(task_array, logger)
        # Create an empty array of results. The status is nil and the exception is pre-populated. If the code
        # runs successfully, all of these default values will be overwritten. If a predecessor task fails, all
        # later task will have the defined exception.
        result = task_array.map do |x|
          Result.new(exception: ::RuntimeError.new('Cancellation - A prior task failed'), args: x.args)
        end

        # Perform the tasks 1 by 1 - each successful task will replace an element in the 'result' array,
        # whereas a failed task will replace the current element with an exception, and all later tasks
        # will not be replaced (thereby being populated with the cancellation error).
        task_counter = 0
        task_array.each do |ele|
          begin
            logger.debug("Begin #{ele.description}")
            output = ele.execute(logger)
            result[task_counter] = Result.new(output: output, status: true, args: ele.args)
          rescue => exc
            logger.debug("Failed #{ele.description}: #{exc.class} #{exc.message}")
            result[task_counter] = Result.new(exception: exc, status: false, args: ele.args)
          end

          if ele.validate(output, logger)
            logger.debug("Success #{ele.description}")
          else
            logger.warn("Failed #{ele.description}")
            result[task_counter].status = false
          end

          break unless result[task_counter].status
          task_counter += 1
        end

        # Return the result
        result
      end
    end
  end
end
