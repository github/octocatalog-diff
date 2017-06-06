# frozen_string_literal: true

require 'json'
require 'open3'
require 'yaml'
require_relative '../catalog'
require_relative '../errors'
require_relative 'parallel'

module OctocatalogDiff
  module Util
    # Helper class to construct catalogs, performing all necessary steps such as
    # bootstrapping directories, installing facts, and running puppet.
    class Catalogs
      # Constructor
      # @param options [Hash] Options
      # @param logger [Logger] Logger object
      def initialize(options, logger)
        @options = options
        @logger = logger
        @catalogs = nil
        raise '@logger must not be nil' if @logger.nil?
      end

      # Compile catalogs. This handles building both the old and new catalog (in parallel) and returns
      # only when both catalogs have been built.
      # @return [Hash] { :from => [OctocatalogDiff::Catalog], :to => [OctocatalogDiff::Catalog] }
      def catalogs
        @catalogs ||= build_catalog_parallelizer
      end

      # Handles the "bootstrap then exit" option, which bootstraps directories but
      # exits without compiling catalogs.
      def bootstrap_then_exit
        @logger.debug('Begin bootstrap_then_exit')
        OctocatalogDiff::CatalogUtil::Bootstrap.bootstrap_directory_parallelizer(@options, @logger)
        @logger.debug('Success bootstrap_then_exit')
        @logger.info('Successfully completed --bootstrap-then-exit action')
      end

      private

      # Parallelizes bootstrapping of directories and building catalogs.
      # @return [Hash] { :from => OctocatalogDiff::Catalog, :to => OctocatalogDiff::Catalog }
      def build_catalog_parallelizer
        # Construct parallel tasks. The array supplied to OctocatalogDiff::Util::Parallel is the task portion
        # of each of the tuples in catalog_tasks.
        catalog_tasks = build_catalog_tasks

        # Update any tasks for catalogs that do not need to be compiled. This is the case when --catalog-only
        # is specified and only one catalog is to be built. This will change matching catalog tasks to the 'noop' type.
        catalog_tasks.map! do |x|
          if @options["#{x[0]}_catalog".to_sym] == '-'
            x[1].args[:backend] = :noop
          elsif @options["#{x[0]}_catalog".to_sym].is_a?(String)
            x[1].args[:json] = File.read(@options["#{x[0]}_catalog".to_sym])
            x[1].args[:backend] = :json
          end
          x
        end

        # Initialize the objects for each parallel task. Initializing the object is very fast and does not actually
        # build the catalog.
        result = {}
        catalog_tasks.each do |x|
          result[x[0]] = OctocatalogDiff::Catalog.new(x[1].args)
          @logger.debug "Initialized #{result[x[0]].builder} for #{x[0]}-catalog"
        end

        # Disable --compare-file-text if either (or both) of the chosen backends do not support it
        if @options.fetch(:compare_file_text, false)
          result.each do |_key, val|
            next unless val.convert_file_resources == false
            @logger.debug "Disabling --compare-file-text; not supported by #{val.builder}"
            @options[:compare_file_text] = false
            catalog_tasks.map! do |x|
              x[1].args[:compare_file_text] = false
              x
            end
            break
          end
        end

        # Inject the starting object into the catalog tasks
        catalog_tasks.map! do |x|
          x[1].args[:object] = result[x[0]]
          x
        end

        # Execute the parallelized catalog builds
        passed_catalog_tasks = catalog_tasks.map { |x| x[1] }
        parallel_catalogs = OctocatalogDiff::Util::Parallel.run_tasks(passed_catalog_tasks, @logger, @options[:parallel])

        # If the catalogs array is empty at this point, there is an unexpected size mismatch. This should
        # never happen, but test for it anyway.
        unless parallel_catalogs.size == catalog_tasks.size
          # :nocov:
          raise "BUG: mismatch catalog_result (#{parallel_catalogs.size} vs #{catalog_tasks.size})"
          # :nocov:
        end

        # If catalogs failed to compile, report that. Prefer to display an actual failure message rather
        # than a generic incomplete parallel task message if there is a more specific message present.
        failures = parallel_catalogs.reject(&:status)
        if failures.any?
          f = failures.reject { |r| r.exception.is_a?(OctocatalogDiff::Util::Parallel::IncompleteTask) }.first
          f ||= failures.first
          raise f.exception
        end

        # Construct result hash. Will eventually be in the format
        # { :from => OctocatalogDiff::Catalog, :to => OctocatalogDiff::Catalog }

        # Analyze the results from parallel run.
        catalog_tasks.each do |x|
          # The `parallel_catalog_obj` is a OctocatalogDiff::Util::Parallel::Result. Get the first element from
          # the parallel_catalogs output.
          parallel_catalog_obj = parallel_catalogs.shift

          # Add the result to the 'result' hash
          add_parallel_result(result, parallel_catalog_obj, x)
        end

        # Things have succeeded if the :to and :from catalogs exist at this point. If not, things have
        # failed, and an exception should be thrown.
        return result if result.key?(:to) && result.key?(:from)

        # This is believed to be a bug condition.
        # :nocov:
        raise OctocatalogDiff::Errors::CatalogError, 'One or more catalogs failed to compile.'
        # :nocov:
      end

      # Get catalog compilation tasks.
      # @return [Array<[key, task]>] Catalog tasks
      def build_catalog_tasks
        [:from, :to].map do |key|
          # These are arguments to OctocatalogDiff::Util::Parallel::Task. In most cases the arguments
          # of OctocatalogDiff::Util::Parallel::Task are taken directly from options, but there are
          # some defaults or otherwise-named options that must be set here.
          args = @options.merge(
            tag: key.to_s,
            branch: @options["#{key}_env".to_sym] || '-',
            bootstrapped_dir: @options["bootstrapped_#{key}_dir".to_sym],
            basedir: @options[:basedir],
            compare_file_text: @options.fetch(:compare_file_text, true),
            retry_failed_catalog: @options.fetch(:retry_failed_catalog, 0),
            parser: @options["parser_#{key}".to_sym]
          )

          # If any options are in the form of 'to_SOMETHING' or 'from_SOMETHING', this sets the option to
          # 'SOMETHING' for the catalog if it matches this key. For example, when compiling the 'to' catalog
          # when an option of :to_some_arg => 'foo', this sets :some_arg => foo, and deletes :to_some_arg and
          # :from_some_arg.
          @options.keys.select { |x| x.to_s =~ /^(to|from)_/ }.each do |opt_key|
            args[opt_key.to_s.sub(/^(to|from)_/, '').to_sym] = @options[opt_key] if opt_key.to_s.start_with?(key.to_s)
            args.delete(opt_key)
          end

          # The task is a OctocatalogDiff::Util::Parallel::Task object that contains the method to execute,
          # validator method, text description, and arguments to provide when calling the method.
          task = OctocatalogDiff::Util::Parallel::Task.new(
            method: method(:build_catalog),
            validator: method(:catalog_validator),
            validator_args: { task: key },
            description: "build_catalog for #{@options["#{key}_env".to_sym]}",
            args: args
          )

          # The format of `catalog_tasks` will be a tuple, where the first element is the key
          # (e.g. :to or :from) and the second element is the OctocatalogDiff::Util::Parallel::Task object.
          [key, task]
        end.compact
      end

      # Given a result from the 'parallel' run and a corresponding (key,task) tuple, add valid
      # catalogs to the 'result' hash and throw errors for invalid catalogs.
      # @param result [Hash] Result hash for build_catalog_parallelizer (may be modified)
      # @param parallel_catalog_obj [OctocatalogDiff::Util::Parallel::Result] Parallel catalog result
      # @param key_task_tuple [Array<key, task>] Key, task tuple
      def add_parallel_result(result, parallel_catalog_obj, key_task_tuple)
        # Expand the tuple into variables
        key, task = key_task_tuple

        # For reporting purposes, get the branch name.
        branch = task.args[:branch]

        # Check the result of the parallel run on this object.
        if parallel_catalog_obj.status.nil?
          # The compile was killed because another task failed.
          @logger.warn "Catalog compile for #{branch} was aborted due to another failure"

        elsif parallel_catalog_obj.output.is_a?(OctocatalogDiff::Catalog)
          # The result is a catalog, but we do not know if it was successfully compiled
          # until we test the validity.
          catalog = parallel_catalog_obj.output
          if catalog.valid?
            # The catalog was successfully compiled.
            result[key] = parallel_catalog_obj.output

            if task.args[:save_catalog]
              File.open(task.args[:save_catalog], 'w') { |f| f.write(catalog.catalog_json) }
              @logger.debug "Saved catalog to #{task.args[:save_catalog]}"
            end
          else
            # The catalog failed, but a catalog object was returned so that better error reporting
            # can take place. In this error reporting, we will replace 'Error:' with '[Puppet Error]'
            # and remove the compilation directory (which is a tmpdir) to reveal only the relative
            # path to the files involved.
            dir = catalog.compilation_dir || ''
            dir_regex = Regexp.new(Regexp.escape(dir) + '/environments/[^/]+/')
            error_display = catalog.error_message.split("\n").map do |line|
              line.sub(/^Error:/, '[Puppet Error]').gsub(dir_regex, '')
            end.join("\n")
            message = "Catalog for #{branch} failed to compile due to errors:\n#{error_display}"
            raise OctocatalogDiff::Errors::CatalogError, message
          end
        else
          # Something unhandled went wrong, and an exception was thrown. Reveal a generic message.
          # :nocov:
          msg = parallel_catalog_obj.exception.message
          message = "Catalog for '#{key}' (#{branch}) failed to compile with #{parallel_catalog_obj.exception.class}: #{msg}"
          message += "\n" + parallel_catalog_obj.exception.backtrace.map { |x| "   #{x}" }.join("\n") if @options[:debug]
          raise OctocatalogDiff::Errors::CatalogError, message
          # :nocov:
        end
      end

      # Performs the steps necessary to build a catalog.
      # @param opts [Hash] Options hash
      # @return [Hash] { :rc => exit code, :catalog => Catalog as JSON string }
      def build_catalog(opts, logger = @logger)
        logger.debug("Setting up Puppet catalog build for #{opts[:branch]}")
        catalog = opts[:object]
        logger.debug("Catalog for #{opts[:branch]} will be built with #{catalog.builder}")
        time_start = Time.now
        catalog.build(logger)
        time_it_took = Time.now - time_start
        retries_str = " retries = #{catalog.retries}" if catalog.retries.is_a?(Integer)
        time_str = "in #{time_it_took} seconds#{retries_str}"
        status_str = catalog.valid? ? 'successfully built' : 'failed'
        logger.debug "Catalog for #{opts[:branch]} #{status_str} with #{catalog.builder} #{time_str}"
        catalog
      end

      # The catalog validator method can indicate failure one of two ways:
      # - Raise an exception (this is preferred, since it gives a specific error message)
      # - Return false (supported but discouraged, since it only surfaces a generic error)
      # @param catalog [OctocatalogDiff::Catalog] Catalog object
      # @param logger [Logger] Logger object (presently unused)
      # @param args [Hash] Additional arguments set specifically for validator
      # @return [Boolean] Return true if catalog is valid, false otherwise
      def catalog_validator(catalog = nil, _logger = @logger, args = {})
        raise ArgumentError, "Expects a catalog, got #{catalog.class}" unless catalog.is_a?(OctocatalogDiff::Catalog)
        raise OctocatalogDiff::Errors::CatalogError, "Catalog failed: #{catalog.error_message}" unless catalog.valid?
        catalog.validate_references if args[:task] == :to # Raises exception for broken references
        true
      end
    end
  end
end
