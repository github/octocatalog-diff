# frozen_string_literal: true

# Handy methods that are not tied to one particular class

module OctocatalogDiff
  module Util
    # Helper class to construct catalogs, performing all necessary steps such as
    # bootstrapping directories, installing facts, and running puppet.
    class Util
      # Utility Method!
      # `is_a?(class)` only allows one method, but this uses an array
      # @param object [?] Object to consider
      # @param classes [Array] Classes to determine if object is a member of
      # @return [Boolean] True if object is_a any of the classes, false otherwise
      def self.object_is_any_of?(object, classes)
        classes.each { |clazz| return true if object.is_a? clazz }
        false
      end

      # Utility Method!
      # `.dup` can't be called on certain objects (Fixnum for example). This
      # method returns the original object if it can't be duplicated.
      def self.safe_dup(object)
        object.dup
      rescue TypeError
        object
      end
    end
  end
end
