# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'shellwords'

module OctocatalogDiff
  module CatalogUtil
    # Used to construct the command to run 'puppet' to construct the catalog.
    class Command
      # Constructor
      def initialize(options = {}, logger = nil)
        @options = options
        @logger = logger

        # Required parameters
        @compilation_dir = options[:compilation_dir]
        raise ArgumentError, 'Compile dir (:compilation_dir) must be a string' unless @compilation_dir.is_a?(String)
        raise Errno::ENOENT, "Compile dir #{@compilation_dir} doesn't exist" unless File.exist?(@compilation_dir)
        raise ArgumentError, "Compile dir #{@compilation_dir} not a directory" unless File.directory?(@compilation_dir)

        @node = options[:node]
        raise ArgumentError, 'Node must be specified to compile catalog' if @node.nil? || !@node.is_a?(String)

        # To be initialized on-demand
        @puppet_argv = nil
        @puppet_binary = nil
      end

      # Retrieve puppet_command, puppet_binary, puppet_argv
      def puppet_argv
        setup
        @puppet_argv
      end

      def puppet_binary
        setup
        @puppet_binary
      end

      def puppet_command
        setup
        [@puppet_binary, @puppet_argv].flatten.join(' ')
      end

      private

      # Build up the command line to run Puppet
      def setup
        return if @puppet_binary && @puppet_argv

        # Where is the puppet binary?
        @puppet_binary = @options[:puppet_binary]
        raise ArgumentError, 'Puppet binary was not supplied' if @puppet_binary.nil?
        raise Errno::ENOENT, "Puppet binary #{@puppet_binary} doesn't exist" unless File.file?(@puppet_binary)

        # Node to compile
        cmdline = []
        cmdline.concat ['master', '--compile', Shellwords.escape(@node)]

        # storeconfigs?
        if @options[:storeconfigs]
          cmdline.concat %w(--storeconfigs --storeconfigs_backend=puppetdb)
        else
          cmdline << '--no-storeconfigs'
        end

        # enc?
        if @options[:enc]
          raise Errno::ENOENT, "Did not find ENC as expected at #{@options[:enc]}" unless File.file?(@options[:enc])
          cmdline << '--node_terminus=exec'
          cmdline << "--external_nodes=#{Shellwords.escape(@options[:enc])}"
        end

        # Future parser?
        cmdline << '--parser=future' if @options[:parser] == :future

        # Path to facts, or a specific fact file?
        facts_terminus = @options.fetch(:facts_terminus, 'yaml')
        if facts_terminus == 'yaml'
          cmdline << "--factpath=#{Shellwords.escape(File.join(@compilation_dir, 'var', 'yaml', 'facts'))}"
          if @options[:fact_file].is_a?(String) && @options[:fact_file] =~ /.*\.(\w+)$/
            fact_file = File.join(@compilation_dir, 'var', 'yaml', 'facts', "#{@node}.#{Regexp.last_match(1)}")
            FileUtils.cp @options[:fact_file], fact_file unless File.file?(fact_file) || @options[:fact_file] == fact_file
          end
          cmdline << '--facts_terminus=yaml'
        elsif facts_terminus == 'facter'
          cmdline << '--facts_terminus=facter'
        else
          raise ArgumentError, "Unrecognized facts_terminus setting: '#{facts_terminus}'"
        end

        # Some typical options for puppet
        cmdline.concat %w(
          --no-daemonize
          --no-ca
          --color=false
          --config_version="/bin/echo catalogscript"
        )

        # Add environment - only make this variable if preserve_environments is used.
        # If preserve_environments is not used, the hard-coded 'production' here matches
        # up with the symlink created under the temporary directory structure.
        environ = @options.fetch(:environment, 'production')
        cmdline << "--environment=#{Shellwords.escape(environ)}"

        # For people who aren't running hiera, a hiera-config will not be generated when @options[:hiera_config]
        # is nil. For everyone else, the hiera config was generated/copied/munged in the 'builddir' class
        # and was installed into the compile directory and named hiera.yaml.
        unless @options[:hiera_config].nil?
          cmdline << "--hiera_config=#{Shellwords.escape(File.join(@compilation_dir, 'hiera.yaml'))}"
        end

        # Options with parameters
        cmdline << "--environmentpath=#{Shellwords.escape(File.join(@compilation_dir, 'environments'))}"
        cmdline << "--vardir=#{Shellwords.escape(File.join(@compilation_dir, 'var'))}"
        cmdline << "--logdir=#{Shellwords.escape(File.join(@compilation_dir, 'var'))}"
        cmdline << "--ssldir=#{Shellwords.escape(File.join(@compilation_dir, 'var', 'ssl'))}"
        cmdline << "--confdir=#{Shellwords.escape(@compilation_dir)}"

        # Other parameters provided by the user
        override_and_append_commandline_with_user_supplied_arguments(cmdline)

        # Return full command
        @puppet_argv = cmdline
      end

      # Private: Mutate the command line with arguments that were passed directly from the
      # user. This appends new arguments and overwrites existing arguments.
      # @param cmdline [Array] Existing command line - mutated by this method
      def override_and_append_commandline_with_user_supplied_arguments(cmdline)
        return unless @options[:command_line].is_a?(Array)

        @options[:command_line].each do |opt|
          # Validate format: Accept '--key=value' or '--key' only.
          unless opt =~ /\A--([^=\s]+)(=.+)?\z/
            raise ArgumentError, "Command line option '#{opt}' does not match format '--SOME_OPTION=SOME_VALUE'"
          end
          key = Regexp.last_match(1)
          val = Regexp.last_match(2)

          # The key should not contain any shell metacharacters. Ensure that this is the case.
          unless key == Shellwords.escape(key)
            raise ArgumentError, "Command line option '#{key}' is invalid."
          end

          # If val is nil, then it's a '--key' argument. Else, it's a '--key=value' argument. Escape
          # the value to ensure it do not break the shell interpretation.
          new_setting = if val.nil?
            "--#{key}"
          else
            "--#{key}=#{Shellwords.escape(val.sub(/\A=/, ''))}"
          end

          # Determine if command line already contains this setting. If yes, the setting provided
          # here should override. If no, then append to the commandline.
          ind = key_position(cmdline, key)
          if ind.nil?
            cmdline << new_setting
          else
            cmdline[ind] = new_setting
          end
        end
      end

      # Private: Determine if the key (given by --key) is already defined in the
      # command line. Returns nil if it is not already defined, otherwise returns
      # the index.
      # @param cmdline [Array] Existing command line
      # @param key [String] Key to look up
      # @return [Integer] Index of where key is defined (nil if undefined)
      def key_position(cmdline, key)
        cmdline.index { |x| x == "--#{key}" || x =~ /\A--#{key}=/ }
      end
    end
  end
end
