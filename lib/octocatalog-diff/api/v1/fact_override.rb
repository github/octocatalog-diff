# frozen_string_literal: true

require 'json'

module OctocatalogDiff
  module API
    module V1
      # Sets up the override of a fact during catalog compilation.
      class FactOverride
        # Accessors
        attr_reader :fact_name, :value

        # Constructor: Accepts a key and value.
        # @param input [Hash] Must contain :fact_name and :value
        def initialize(input)
          @fact_name = input.fetch(:fact_name)
          @value = input.fetch(:value)
        end

        # Retrieve the fact_name as #key (essentially an alias)
        # @return [String] Value of @fact_name
        def key
          @fact_name
        end
      end
    end
  end
end
