# frozen_string_literal: true

require_relative '../filter'

module OctocatalogDiff
  module CatalogDiff
    class Filter
      # Filter out changes in parameters where the elements of an array are the
      # same values but different data types. For example, this would filter out
      # the following diffs:
      #   Exec[some command] =>
      #    parameters =>
      #      returns =>
      #        - ["0", "1"]
      #        + [0, 1]
      class EquivalentArrayNoDatatypes < OctocatalogDiff::CatalogDiff::Filter
        # Public: Implement the filter for arrays that have the same elements
        # but possibly different data types.
        #
        # @param diff [OctocatalogDiff::API::V1::Diff] Difference
        # @param _options [Hash] Additional options (there are none for this filter)
        # @return [Boolean] true if this should be filtered out, false otherwise
        def filtered?(diff, _options = {})
          # Skip additions or removals - focus only on changes
          return false unless diff.change?
          old_value = diff.old_value
          new_value = diff.new_value

          # Skip unless both the old and new values are arrays.
          return false unless old_value.is_a?(Array) && new_value.is_a?(Array)

          # Avoid generating comparable values if the arrays are a different
          # size, because there's no possible way that they are equivalent.
          return false unless old_value.size == new_value.size

          # Generate and then compare the comparable arrays.
          old_value.map { |x| comparable_value(x) } == new_value.map { |x| comparable_value(x) }
        end

        # Private: Get a more easily comparable value for an array element.
        # Integers, floats, and strings that look like integers or floats become
        # floats, and symbols are converted to string representation.
        #
        # @param input [any] Value to convert
        # @return [any] "Comparable" value
        def comparable_value(input)
          # Any string that looks like a number is converted to a float.
          if input.is_a?(String) && input =~ /\A-?(([0-9]*\.[0-9]+)|([0-9]+))\z/
            return input.to_f
          end

          # Any number is converted to a float
          return input.to_f if input.is_a?(Integer) || input.is_a?(Float)

          # Symbols are converted to ":xxx" strings.
          return ":#{input}" if input.is_a?(Symbol)

          # Everything else is unconverted.
          input
        end
      end
    end
  end
end
