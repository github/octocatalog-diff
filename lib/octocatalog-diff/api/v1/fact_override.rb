# frozen_string_literal: true

require 'json'

module OctocatalogDiff
  module API
    module V1
      # Sets up the override of a fact during catalog compilation.
      class FactOverride
        # Accessors
        attr_reader :key, :value

        # Constructor: Accepts a key and value.
        # @param input [Hash] Must contain :key and :value
        def initialize(input)
          @key = input.fetch(:key)
          @value = input.fetch(:value)
        end
      end
    end
  end
end
