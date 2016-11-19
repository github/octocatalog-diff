# frozen_string_literal: true

require_relative '../facts'

require 'json'

module OctocatalogDiff
  class Facts
    # Deal with facts in JSON files
    class JSON
      # @param options [Hash] Options hash specifically for this fact type.
      #          - :fact_file_string [String] => Fact data as a string
      # @param node [String] Node name (overrides node name from fact data)
      # @return [Hash] Facts
      def self.fact_retriever(options = {}, node = '')
        facts = ::JSON.parse(options.fetch(:fact_file_string))
        node = facts.fetch('fqdn', 'unknown.node') if node.empty?
        { 'name' => node, 'values' => facts }
      end
    end
  end
end
