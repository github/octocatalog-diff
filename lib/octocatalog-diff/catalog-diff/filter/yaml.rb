# frozen_string_literal: true

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
        # @param diff [Array] Difference
        # @param _options [Hash] Additional options (there are none for this filter)
        # @return [Boolean] true if this difference is a YAML file with identical objects, false otherwise
        def filtered?(diff, _options = {})
          # Skip additions or removals - focus only on changes
          return false unless diff[0] == '~' || diff[0] == '!'

          # Make sure we are comparing file content for a file ending in .yaml or .yml extension
          return false unless diff[1] =~ /^File\f([^\f]+)\.ya?ml\fparameters\fcontent$/

          # Attempt to convert the old (diff[2]) and new (diff[3]) into YAML objects. Assuming
          # that doesn't error out, the return value is whether or not they're equal.
          obj_old = ::YAML.load(diff[2])
          obj_new = ::YAML.load(diff[3])
          obj_old == obj_new
        rescue # Rescue everything - if something failed, we aren't sure what's going on, so we'll return false.
          false
        end
      end
    end
  end
end
