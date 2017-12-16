# frozen_string_literal: true

require_relative '../filter'

require 'set'

module OctocatalogDiff
  module CatalogDiff
    class Filter
      # Filter out changes in parameters when one catalog has a parameter that's a string and
      # the other catalog has that same parameter as an array containing the same string.
      # For example, under this filter, the following is not a change:
      #   catalog1: notify => "Service[foo]"
      #   catalog2: notify => ["Service[foo]"]
      class SingleItemArray < OctocatalogDiff::CatalogDiff::Filter
        # Public: Implement the filter for single-item arrays whose item exactly matches the
        # item that's not in an array in the other catalog.
        #
        # @param diff [OctocatalogDiff::API::V1::Diff] Difference
        # @param _options [Hash] Additional options (there are none for this filter)
        # @return [Boolean] true if this difference is a YAML file with identical objects, false otherwise
        def filtered?(_diff, _options = {})
          false
        end
      end
    end
  end
end
