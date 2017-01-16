# frozen_string_literal: true

require_relative '../filter'

require 'yaml'

module OctocatalogDiff
  module CatalogDiff
    class Filter
      # Filter based on equivalence of YAML objects for file resources with named extensions.
      class YAML < OctocatalogDiff::CatalogDiff::Filter
        # Public: Actually do the comparison of YAML objects for appropriate resources.
        # Return true if the YAML objects are known to be equivalent. Return false if they
        # are not equivalent, or if equivalence cannot be determined.
        #
        # @param diff_in [OctocatalogDiff::API::V1::Diff] Difference
        # @param _options [Hash] Additional options (there are none for this filter)
        # @return [Boolean] true if this difference is a YAML file with identical objects, false otherwise
        def filtered?(diff, _options = {})
          # Skip additions or removals - focus only on changes
          return false unless diff.change?

          # Make sure we are comparing file content for a file ending in .yaml or .yml extension
          return false unless diff.type == 'File' && diff.structure == %w(parameters content)
          return false unless diff.title =~ /\.ya?ml\z/

          # Attempt to convert the old value and new value into YAML objects. Assuming
          # that doesn't error out, the return value is whether or not they're equal.
          obj_old = ::YAML.load(diff.old_value)
          obj_new = ::YAML.load(diff.new_value)
          obj_old == obj_new
        rescue # Rescue everything - if something failed, we aren't sure what's going on, so we'll return false.
          false
        end
      end
    end
  end
end
