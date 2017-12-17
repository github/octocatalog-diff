# frozen_string_literal: true

require_relative '../filter'

module OctocatalogDiff
  module CatalogDiff
    class Filter
      # Filter out changes in parameters when one catalog has a parameter that's an object and
      # the other catalog has that same parameter as an array containing the same object.
      # For example, under this filter, the following is not a change:
      #   catalog1: notify => "Service[foo]"
      #   catalog2: notify => ["Service[foo]"]
      class SingleItemArray < OctocatalogDiff::CatalogDiff::Filter
        # Public: Implement the filter for single-item arrays whose item exactly matches the
        # item that's not in an array in the other catalog.
        #
        # @param diff [OctocatalogDiff::API::V1::Diff] Difference
        # @param _options [Hash] Additional options (there are none for this filter)
        # @return [Boolean] true if this should be filtered out, false otherwise
        def filtered?(diff, _options = {})
          # Skip additions or removals - focus only on changes
          return false unless diff.change?
          old_value = diff.old_value
          new_value = diff.new_value

          # Skip unless there is a single-item array under consideration
          return false unless
            (old_value.is_a?(Array) && old_value.size == 1) ||
            (new_value.is_a?(Array) && new_value.size == 1)

          # Skip if both the old value and new value are arrays
          return false if old_value.is_a?(Array) && new_value.is_a?(Array)

          # Do comparison
          if old_value.is_a?(Array)
            old_value.first == new_value
          else
            new_value.first == old_value
          end
        end
      end
    end
  end
end
