# frozen_string_literal: true

# Execute a built-in script (which can also be overridden with a user-supplied script)

require 'fileutils'
require 'open3'
require 'shellwords'

module OctocatalogDiff
  module Util
    # This is a utility class to execute a built-in script.
    class ScriptRunner
      attr_reader :script, :logger

      # Create the object - the object is a configured script, which can be executed multiple
      # times with different environment varibles.
      #
      # @param opts [Hash] Options hash
      #   opts[:default_script] (Required) Path to script, relative to `scripts` directory
      #   opts[:logger] (Required) Logger object
      #   opts[:override_script_path] (Optional) Directory where a similarly-named script MAY exist
      def initialize(opts = {})
        @logger = opts.fetch(:logger)
        @script = find_script(opts.fetch(:default_script), opts[:override_script_path])
      end

      # Execute the script from a given working directory, with additional environment variables
      # specified in the options hash.
      #
      # @param opts [Hash] Options hash
      #   opts[:working_dir] (Required) Directory where script is to be executed
      #   opts[<STRING>] (Optional) Environment variable
      def run(opts = {})
        working_dir = opts.fetch(:working_dir)
        assert_directory_exists(working_dir)
      end

      private

      def find_script(default_script, override_script_path)
        if override_script_path
          script_test = File.join(override_script_path, File.basename(default_script))
          if File.file?(script_test)
            logger.debug "Selecting #{script_test} from override script path"
            return script_test
          else
            logger.debug "Did not find #{script_test} in override script path"
          end
        end

        script = File.expand_path("../../../scripts/#{default_script}", File.dirname(__FILE__))
        return script if File.file?(script)

        raise Errno::ENOENT, "Unable to locate default script '#{default_script}'"
      end

      def assert_directory_exists(dir)
        return if File.directory?(dir)
        raise Errno::ENOENT, "Invalid directory '#{dir}'"
      end
    end
  end
end
