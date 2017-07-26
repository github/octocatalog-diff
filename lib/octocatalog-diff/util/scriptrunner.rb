# frozen_string_literal: true

# Execute a built-in script (which can also be overridden with a user-supplied script)

require 'fileutils'
require 'open3'
require 'shellwords'

module OctocatalogDiff
  module Util
    # This is a utility class to execute a built-in script.
    class ScriptRunner
      # For an exception running the script
      class ScriptException < RuntimeError; end

      attr_reader :script, :script_src, :logger, :stdout, :stderr, :exitcode

      # Create the object - the object is a configured script, which can be executed multiple
      # times with different environment varibles.
      #
      # @param opts [Hash] Options hash
      #   opts[:default_script] (Required) Path to script, relative to `scripts` directory
      #   opts[:logger] (Optional) Logger object
      #   opts[:override_script_path] (Optional) Directory where a similarly-named script MAY exist
      def initialize(opts = {})
        @logger = opts[:logger]
        @script_src = find_script(opts.fetch(:default_script), opts[:override_script_path])
        @script = temp_script(@script_src)
        @stdout = nil
        @stderr = nil
        @exitcode = nil
      end

      # Execute the script from a given working directory, with additional environment variables
      # specified in the options hash.
      #
      # @param opts [Hash] Options hash
      #   opts[:working_dir] (Required) Directory where script is to be executed
      #   opts[:argv] (Optional Array) Command line arguments
      #   opts[:pass_env_vars] (Optional Array) Environment variables to pass (default: HOME, PATH)
      #   opts[<STRING>] (Optional) Environment variable
      def run(opts = {})
        working_dir = opts.fetch(:working_dir)
        assert_directory_exists(working_dir)

        argv = opts.fetch(:argv, [])
        logger = opts[:logger] || @logger

        pass_env_vars = [opts[:pass_env_vars], 'HOME', 'PATH'].flatten.compact
        env = opts.select { |k, _v| k.is_a?(String) }
        pass_env_vars.each { |var| env[var] ||= ENV[var] }
        env['PWD'] = working_dir

        cmdline = [script, argv].flatten.compact.map { |x| Shellwords.escape(x) }.join(' ')
        log(:debug, "Execute: #{cmdline}", opts[:logger])

        @stdout, @stderr, status = Open3.capture3(env, cmdline, unsetenv_others: true, chdir: working_dir)
        @exitcode = status.exitstatus

        @stderr.split(/\n/).select { |line| line =~ /\S/ }.each { |line| log(:debug, "STDERR: #{line}", logger) }
        log(:debug, "Exit status: #{@exitcode}", logger)
        return @stdout if @exitcode.zero?
        raise ScriptException, output
      end

      # All output from the latest execution of the command.
      # @return [String] Combined output of STDOUT and STDERR
      def output
        return if @exitcode.nil?
        [
          'STDOUT:',
          @stdout.split(/\n/).map { |line| "  #{line}" },
          'STDERR:',
          @stderr.split(/\n/).map { |line| "  #{line}" }
        ].flatten.compact.join("\n")
      end

      private

      # PRIVATE: Log a message, if logger is defined. Since this might be called under `parallel`
      # it's possible that the logger isn't defined, and if so the logged message is skipped.
      def log(priority, message, logger = @logger)
        return unless logger
        logger.send(priority, [message])
      end

      # PRIVATE: Create a temporary file with the contents of the script and mark the script executable.
      # This is to avoid changing ownership or permissions on any user-supplied file.
      #
      # @param script [String] Path to script
      # @return [String] Path to tempfile containing script
      def temp_script(script)
        raise Errno::ENOENT, "Script '#{script}' not found" unless File.file?(script)
        temp_dir = Dir.mktmpdir('ocd-scriptrunner-')
        at_exit do
          begin
            FileUtils.remove_entry_secure temp_dir
          rescue Errno::ENOENT # rubocop:disable Lint/HandleExceptions
            # OK if the directory doesn't exist since we're trying to remove it anyway
          end
        end
        temp_file = File.join(temp_dir, File.basename(script))
        File.open(temp_file, 'w') { |f| f.write(File.read(script)) }
        FileUtils.chmod 0o755, temp_file
        temp_file
      end

      # PRIVATE: Determine the path to the script to execute, taking into account the default script
      # location and the optional override script path.
      #
      # @param default_script [String] Path to script, relative to `scripts` directory
      # @param override_script_path [String] Optional directory with override script
      # @return [String] Full path to script
      def find_script(default_script, override_script_path = nil)
        script = find_script_from_override_path(default_script, override_script_path) ||
                 File.expand_path("../../../scripts/#{default_script}", File.dirname(__FILE__))
        raise Errno::ENOENT, "Unable to locate script '#{script}'" unless File.file?(script)
        script
      end

      # PRIVATE: Find script from override path.
      #
      # @param default_script [String] Path to script, relative to `scripts` directory
      # @param override_script_path [String] Optional directory
      # @return [String] Override script if found, else nil
      def find_script_from_override_path(default_script, override_script_path = nil)
        return unless override_script_path
        script_test = File.join(override_script_path, File.basename(default_script))
        if File.file?(script_test)
          log(:debug, "Selecting #{script_test} from override script path")
          script_test
        else
          log(:debug, "Did not find #{script_test} in override script path")
          nil
        end
      end

      # PRIVATE: Assert that a directory exists (and is a directory). Raise error if not.
      #
      # @param dir [String] Directory to test
      def assert_directory_exists(dir)
        return if File.directory?(dir)
        raise Errno::ENOENT, "Invalid directory '#{dir}'"
      end
    end
  end
end
