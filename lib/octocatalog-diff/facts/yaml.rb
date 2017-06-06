# frozen_string_literal: true

require_relative '../facts'
require 'yaml'

module OctocatalogDiff
  class Facts
    # Deal with facts in YAML files
    class Yaml
      # Manipulate a YAML file so it can be parsed and return the facts as a hash.
      # If we leave it as Puppet::Node::Facts then it will require us to load puppet
      # gems in order to parse it, and that's too heavy for simple fact retrieval.
      # @param options [Hash] Options hash specifically for this fact type.
      #          - :fact_file_string [String] => Fact data as a string
      # @param node [String] Node name (overrides node name from fact data)
      # @return [Hash] Facts
      def self.fact_retriever(options = {}, node = '')
        fact_file_string = options.fetch(:fact_file_string)

        # Touch up the first line before parsing.
        fact_file_data = fact_file_string.split(/\n/)
        fact_file_data[0] = '---' if fact_file_data[0] =~ /^---/

        # Load the parsed fact file.
        parsed = YAML.load(fact_file_data.join("\n"))

        # This is a handler for a YAML file that has just the facts and none of the
        # structure. For example if you saved the output of `facter -y` to a file and
        # are passing that in, this will work.
        result = if parsed.key?('name') && parsed.key?('values')
          parsed
        else
          { 'name' => node || parsed['fqdn'] || '', 'values' => parsed }
        end

        result['name'] = node unless node == ''
        result
      end
    end
  end
end
