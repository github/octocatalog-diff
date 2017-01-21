# frozen_string_literal: true

require 'json'

require_relative '../api/v1'

module OctocatalogDiff
  class Cli
    # Helper methods for fact override parsing.
    class FactOverride
      # Public: Given an input string, construct the fact override object(s).
      #
      # @param input [String] Input in the format: key=(data type)value
      # @return [OctocatalogDiff::API::V1::FactOverride] Constructed override object
      def self.fact_override(input, key = nil)
        OctocatalogDiff::API::V1::Override.create_from_input(input, key)
      end
    end
  end
end
