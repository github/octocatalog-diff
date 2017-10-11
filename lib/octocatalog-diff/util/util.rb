# frozen_string_literal: true

# Handy methods that are not tied to one particular class

require 'fileutils'

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
      # @param object [?] Object to consider
      # @return [?] Duplicated object if possible, otherwise the original object
      def self.safe_dup(object)
        object.dup
      rescue TypeError
        object
      end

      # Utility Method!
      # This does a "deep" duplication via recursion. Handles hashes and arrays.
      # @param object [?] Object to consider
      # @return [?] Duplicated object
      def self.deep_dup(object)
        if object.is_a?(Hash)
          result = {}
          object.each { |k, v| result[k] = deep_dup(v) }
          result
        elsif object.is_a?(Array)
          object.map { |ele| deep_dup(ele) }
        else
          safe_dup(object)
        end
      end

      # Utility Method!
      # This creates a temporary directory. If the base directory is specified, then we
      # do not remove the temporary directory at exit, because we assume that something
      # else will remove the base directory.
      #
      # prefix  - A String with the prefix for the temporary directory
      # basedir - A String with the directory in which to make the tempdir
      #
      # Returns the full path to the temporary directory.
      def self.temp_dir(prefix = 'ocd-', basedir = nil)
        # If the base directory is specified, make sure it exists, and then create the
        # temporary directory within it.
        if basedir
          unless File.directory?(basedir)
            raise Errno::ENOENT, "temp_dir: Base dir #{basedir.inspect} does not exist!"
          end
          return Dir.mktmpdir(prefix, basedir)
        end

        # If the base directory was not specified, then create a temporary directory, and
        # send the `at_exit` to clean it up at the conclusion.
        the_dir = Dir.mktmpdir(prefix)
        at_exit do
          begin
            FileUtils.remove_entry_secure the_dir
          rescue Errno::ENOENT # rubocop:disable Lint/HandleExceptions
            # OK if the directory doesn't exist since we're trying to remove it anyway
          end
        end
        the_dir
      end
    end
  end
end
