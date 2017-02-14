# frozen_string_literal: true

require_relative '../filter'

require 'json'

module OctocatalogDiff
  module CatalogDiff
    class Filter
      # Filter based on equivalence of JSON objects for file resources with named extensions.
      class JSON < OctocatalogDiff::CatalogDiff::Filter
        # Public: Actually do the comparison of JSON objects for appropriate resources.
        # Return true if the JSON objects are known to be equivalent. Return false if they
        # are not equivalent, or if equivalence cannot be determined.
        #
        # @param diff_in [OctocatalogDiff::API::V1::Diff] Difference
        # @param _options [Hash] Additional options (there are none for this filter)
        # @return [Boolean] true if this difference is a JSON file with identical objects, false otherwise
        def filtered?(diff, _options = {})
          # Skip additions or removals - focus only on changes
          return false unless diff.change?

          # Make sure we are comparing file content for a file ending in .json extension
          return false unless diff.type == 'File' && diff.structure == %w(parameters content)
          return false unless diff.title =~ /\.json\z/i

          # Attempt to convert the old value and new value into JSON objects. Assuming
          # that doesn't error out, the return value is whether or not they're equal.
          obj_old = ::JSON.parse(diff.old_value)
          obj_new = ::JSON.parse(diff.new_value)
          obj_old == obj_new
        rescue # Rescue everything - if something failed, we aren't sure what's going on, so we'll return false.
          false
        end
      end
    end
  end
end
