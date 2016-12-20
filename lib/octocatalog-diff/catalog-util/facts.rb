# frozen_string_literal: true

require_relative '../facts'

module OctocatalogDiff
  module CatalogUtil
    # Helper class to construct a fact object based on options provided by
    # cli/options. Supports a direct fact file, looking up a YAML file based on
    # node name within Puppet fact directories, or retrieving from PuppetDB.
    class Facts
      # Constructor
      # @param options [Hash] Options from cli/options
      # @param logger [Logger] Logger object for debug messages (optional)
      def initialize(options, logger = nil)
        raise ArgumentError, "Argument to constructor must be Hash not #{options.class}" unless options.is_a?(Hash)
        @options = options.dup
        @logger = logger

        # Environment variable recognition
        @options[:puppetdb_url] ||= ENV['PUPPETDB_URL'] if ENV['PUPPETDB_URL']
        @options[:puppet_fact_dir] ||= ENV['PUPPET_FACT_DIR'] if ENV['PUPPET_FACT_DIR']
      end

      # Compute facts if needed and then return them
      # @return [Hash] Facts
      def facts
        @facts ||= compute_facts
      end

      private

      # Retrieve facts from a YAML file in the puppet facts directory
      # @param filename [String] Full path to file to read in
      # @return [OctocatalogDiff::Facts] Facts object
      def facts_from_file(filename)
        @logger.debug("Retrieving facts from #{filename}") unless @logger.nil?
        opts = {
          node: @options[:node],
          backend: :yaml,
          fact_file_string: File.read(filename)
        }
        OctocatalogDiff::Facts.new(opts)
      end

      # Retrieve facts from PuppetDB. Either options[:puppetdb_url] or ENV['PUPPETDB_URL']
      # needs to be set for this to work. Node name must also be set in options.
      # @return [OctocatalogDiff::Facts] Facts object
      def facts_from_puppetdb
        @logger.debug('Retrieving facts from PuppetDB') unless @logger.nil?
        OctocatalogDiff::Facts.new(@options.merge(backend: :puppetdb, retry: 2))
      end

      # Error message when the node is needed but not defined
      # :nocov:
      def error_node_not_provided
        message = 'Unable to determine facts. You must either supply "--fact-file FILENAME"' \
                  ' or a node name "-n NODENAME" to look up a set of node facts in a fact' \
                  ' directory or in PuppetDB.'
        raise ArgumentError, message
      end
      # :nocov:

      # Does the actual computation/lookup of facts. Seeks to return a OctocatalogDiff::Facts
      # object. Raises error if no fact sources are found.
      # @return [OctocatalogDiff::Facts] Facts object
      def compute_facts
        if @options.key?(:facts) && @options[:facts].is_a?(OctocatalogDiff::Facts)
          return @options[:facts]
        end

        if @options.key?(:fact_file)
          raise Errno::ENOENT, 'Specified fact file does not exist' unless File.file?(@options[:fact_file])
          return facts_from_file(@options[:fact_file])
        end

        error_node_not_provided if @options[:node].nil?

        if @options[:puppet_fact_dir] && File.directory?(@options[:puppet_fact_dir])
          filename = File.join(@options[:puppet_fact_dir], @options[:node] + '.yaml')
          return facts_from_file(filename) if File.file?(filename)
        end

        return facts_from_puppetdb if @options[:puppetdb_url]

        message = 'Unable to compute facts for node. Please use "--fact-file FILENAME" option' \
                  ' or set one of these environment variables: PUPPET_FACT_DIR or PUPPETDB_URL.'
        raise ArgumentError, message
      end
    end
  end
end
