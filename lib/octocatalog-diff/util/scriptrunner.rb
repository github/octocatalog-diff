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

      def initialize(opts = {})
        default_script = opts.fetch(:default_script)
        working_dir = opts.fetch(:working_dir)
        override_script_path = opts[:override_script_path]
        @logger = opts.fetch(:logger)

        @script = find_script(default_script, override_script_path)
        assert_directory_exists(working_dir)
      end

      def run(opts = {})
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
