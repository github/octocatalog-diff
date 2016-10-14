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
      end

      # Build up the command line to run Puppet
      def puppet_command
        cmdline = []

        # Where is the puppet binary?
        puppet = @options[:puppet_binary]
        raise ArgumentError, 'Puppet binary was not supplied' if puppet.nil?
        raise Errno::ENOENT, "Puppet binary #{puppet} doesn't exist" unless File.file?(puppet)
        cmdline << puppet

        # Node to compile
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
          cmdline << "--node_terminus=exec --external_nodes=#{Shellwords.escape(@options[:enc])}"
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
          --environment=production
        )

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

        # Return full command
        cmdline.join(' ')
      end
    end
  end
end
