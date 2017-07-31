# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'stringio'

require_relative '../catalog'
require_relative '../catalog-util/bootstrap'
require_relative '../catalog-util/builddir'
require_relative '../catalog-util/command'
require_relative '../catalog-util/facts'
require_relative '../util/puppetversion'
require_relative '../util/scriptrunner'

module OctocatalogDiff
  class Catalog
    # Represents a Puppet catalog that is computed (via `puppet master --compile ...`)
    # By instantiating this class, the catalog is computed.
    class Computed < OctocatalogDiff::Catalog
      # Constructor
      # @param :node [String] REQUIRED: Node name
      # @param :basedir [String] Directory in which to compile the catalog
      # @param :pass_env_vars [Array<String>] Environment variables to pass when compiling catalog
      # @param :retry_failed_catalog [Integer] Number of retries if a catalog compilation fails
      # @param :tag [String] For display purposes, the catalog being compiled
      # @param :puppet_binary [String] Full path to Puppet
      # @param :puppet_version [String] Puppet version (optional; if not supplied, it is calculated)
      # @param :puppet_command [String] Full command to run Puppet (optional; if not supplied, it is calculated)
      def initialize(options)
        super

        raise ArgumentError, 'Node name must be passed to OctocatalogDiff::Catalog::Computed' unless options[:node].is_a?(String)
        raise ArgumentError, 'Branch is undefined' unless options[:branch]

        # Additional class variables
        @pass_env_vars = options.fetch(:pass_env_vars, [])
        @retry_failed_catalog = options.fetch(:retry_failed_catalog, 0)
        @tag = options.fetch(:tag, 'catalog')
        @puppet_binary = options[:puppet_binary]
        @puppet_version = options[:puppet_version]
        @puppet_command = options[:puppet_command]
        @builddir = nil
        @facts_terminus = options.fetch(:facts_terminus, 'yaml')
      end

      # Get the Puppet version
      # @return [String] Puppet version
      def puppet_version
        raise ArgumentError, '"puppet_binary" was not passed to OctocatalogDiff::Catalog::Computed' unless @puppet_binary
        @puppet_version ||= OctocatalogDiff::Util::PuppetVersion.puppet_version(@puppet_binary, @options)
      end

      # Compilation directory
      # @return [String] Compilation directory
      def compilation_dir
        raise 'Catalog was not built' if @builddir.nil?
        @builddir.tempdir
      end

      # Environment used to compile catalog
      def environment
        @options.fetch(:environment, 'production')
      end

      # Convert file resources source => "puppet:///..." to content => "actual content of file".
      def convert_file_resources(dry_run = false)
        return @options.key?(:basedir) if dry_run
        return false unless @options[:basedir]
        OctocatalogDiff::CatalogUtil::FileResources.convert_file_resources(self, environment)
      end

      private

      # Private method: Clean up a checkout directory, if it exists
      def cleanup_checkout_dir(checkout_dir, logger)
        return unless File.directory?(checkout_dir)
        logger.debug("Cleaning up temporary directory #{checkout_dir}")
        # Sometimes this seems to break when handling the recursive removal when running under
        # a parallel environment. Trap and ignore the errors here if we don't care about them.
        begin
          FileUtils.remove_entry_secure checkout_dir
          # :nocov:
        rescue Errno::ENOTEMPTY, Errno::ENOENT => exc
          logger.debug "cleanup_checkout_dir(#{checkout_dir}) logged #{exc.class} - this can be ignored"
          # :nocov:
        end
      end

      # Private method: Bootstrap a directory
      def bootstrap(logger)
        return if @builddir

        # Fill options for creating and populating the temporary directory
        tmphash = @options.dup

        # Bootstrap directory if needed
        if !@options[:bootstrapped_dir].nil?
          raise Errno::ENOENT, "Invalid dir #{@options[:bootstrapped_dir]}" unless File.directory?(@options[:bootstrapped_dir])
          tmphash[:basedir] = @options[:bootstrapped_dir]
        elsif @options[:branch] == '.'
          if @options[:bootstrap_current]
            tmphash[:basedir] =  Dir.mktmpdir('ocd-bootstrap-basedir-')
            at_exit { cleanup_checkout_dir(tmphash[:basedir], logger) }

            FileUtils.cp_r File.join(@options[:basedir], '.'), tmphash[:basedir]

            o = @options.reject { |k, _v| k == :branch }.merge(path: tmphash[:basedir])
            OctocatalogDiff::CatalogUtil::Bootstrap.bootstrap_directory(o, logger)
          else
            tmphash[:basedir] = @options[:basedir]
          end
        else
          checkout_dir = Dir.mktmpdir('ocd-bootstrap-checkout-')
          at_exit { cleanup_checkout_dir(checkout_dir, logger) }
          tmphash[:basedir] = checkout_dir
          OctocatalogDiff::CatalogUtil::Bootstrap.bootstrap_directory(@options.merge(path: checkout_dir), logger)
        end

        # Create and populate the temporary directory
        @builddir ||= OctocatalogDiff::CatalogUtil::BuildDir.new(tmphash, logger)
      end

      # Private method: Build catalog by running Puppet
      # @param logger [Logger] Logger object
      def build_catalog(logger)
        if @facts_terminus != 'facter'
          facts_obj = OctocatalogDiff::CatalogUtil::Facts.new(@options, logger)
          logger.debug "Start retrieving facts for #{@node} from #{self.class}"
          @options[:facts] = facts_obj.facts
          logger.debug "Success retrieving facts for #{@node} from #{self.class}"
        end

        bootstrap(logger)
        result = run_puppet(logger)
        @retries = result[:retries]
        if (result[:exitcode]).zero?
          begin
            @catalog = ::JSON.parse(result[:stdout])
            @catalog_json = result[:stdout]
            @error_message = nil
          rescue ::JSON::ParserError => exc
            @catalog = nil
            @catalog_json = nil
            @error_message = "Catalog has invalid JSON: #{exc.message}"
          end
        else
          @error_message = result[:stderr]
          @catalog = nil
          @catalog_json = nil
        end
      end

      # Get the command to compile the catalog
      # @return [String] Puppet command line
      def puppet_command
        puppet_command_obj.puppet_command
      end

      def puppet_command_obj
        @puppet_command_obj ||= begin
          raise ArgumentError, '"puppet_binary" was not passed to OctocatalogDiff::Catalog::Computed' unless @puppet_binary

          command_opts = @options.merge(
            node: @node,
            compilation_dir: @builddir.tempdir,
            parser: @options.fetch(:parser, :default),
            puppet_binary: @puppet_binary,
            fact_file: @builddir.fact_file,
            dir: @builddir.tempdir,
            enc: @builddir.enc
          )
          OctocatalogDiff::CatalogUtil::Command.new(command_opts)
        end
      end

      # Private method: Actually execute puppet
      # @return [Hash] { stdout, stderr, exitcode }
      def exec_puppet(logger)
        # This is the environment provided to the puppet command.
        env = {}
        @pass_env_vars.each { |var| env[var] ||= ENV[var] }

        # This is the Puppet command itself
        env['OCD_PUPPET_BINARY'] = @puppet_command_obj.puppet_binary

        # Additional passed-in options
        sr_run_opts = env.merge(
          logger: logger,
          working_dir: @builddir.tempdir,
          argv: @puppet_command_obj.puppet_argv
        )

        # Set up the ScriptRunner
        scriptrunner = OctocatalogDiff::Util::ScriptRunner.new(
          default_script: 'puppet/puppet.sh',
          override_script_path: @options[:override_script_path]
        )

        begin
          scriptrunner.run(sr_run_opts)
        rescue OctocatalogDiff::Util::ScriptRunner::ScriptException => exc
          logger.warn "Puppet command failed: #{exc.message}" if logger
        end

        {
          stdout: scriptrunner.stdout,
          stderr: scriptrunner.stderr,
          exitcode: scriptrunner.exitcode
        }
      end

      # Private method: Make sure that the Puppet environment directory exists.
      def assert_that_puppet_environment_directory_exists
        target_dir = File.join(@builddir.tempdir, 'environments', environment)
        return if File.directory?(target_dir)
        raise Errno::ENOENT, "Environment directory #{target_dir} does not exist"
      end

      # Private method: Runs puppet on the command line to compile the catalog
      # Exit code is 0 if catalog generation was successful, non-zero otherwise.
      # @param logger [Logger] Logger object
      # @return [Hash] { stdout: <catalog as JSON>, stderr: <error messages>, exitcode: <hopefully 0> }
      def run_puppet(logger)
        assert_that_puppet_environment_directory_exists

        # Run 'cmd' with environment 'env' from directory 'dir'
        # First line of a successful result needs to be stripped off. It will look like:
        # Notice: Compiled catalog for xxx in environment production in 27.88 seconds
        retval = {}
        0.upto(@retry_failed_catalog) do |retry_num|
          @retries = retry_num
          time_begin = Time.now
          logger.debug("(#{@tag}) Try #{1 + retry_num} executing Puppet #{puppet_version}: #{puppet_command}")
          result = exec_puppet(logger)

          # Success
          if (result[:exitcode]).zero?
            logger.debug("(#{@tag}) Catalog succeeded on try #{1 + retry_num} in #{Time.now - time_begin} seconds")
            first_brace = result[:stdout].index('{') || 0
            retval = {
              stdout: result[:stdout][first_brace..-1],
              stderr: nil,
              exitcode: 0,
              retries: retry_num
            }
            break
          end

          # Failure
          logger.debug("(#{@tag}) Catalog failed on try #{1 + retry_num} in #{Time.now - time_begin} seconds")
          retval = result.merge(retries: retry_num)
        end
        retval
      end
    end
  end
end
