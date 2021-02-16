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

        if facts.keys.include?('name') && facts.keys.include?('values') && facts['values'].is_a?(Hash)
          # If you saved the output of something like
          # `puppet facts find $(hostname)` the structure will already be a
          # {'name' => <fqdn>, 'values' => <hash of facts>}. We do nothing
          # here because we don't want to double-encode.
        else
          facts = { 'name' => node, 'values' => facts }
        end

        facts['name'] = node unless node.empty?
        facts['name'] = facts['values'].fetch('fqdn', 'unknown.node') if facts['name'].empty?
        facts
      end
    end
  end
end
