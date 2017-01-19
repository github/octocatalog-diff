# frozen_string_literal: true

require_relative 'common'

module OctocatalogDiff
  module API
    module V1
      # This class represents a `diff` produced by a catalog-diff operation. This has traditionally
      # been stored as an array with:
      #   [0] Type of change - '+', '-', '!', '~'
      #   [1] Type, title, and maybe structure, delimited by "\f"
      #   [2] Content of the "old" catalog
      #   [3] Content of the "new" catalog
      #   [4] File and line of the "old" catalog
      #   [5] File and line of the "new" catalog
      # This object seeks to preserve this traditional structure, while providing methods to make it
      # easier to deal with. We recommend using the named options, rather than #raw or the indexed array,
      # as the raw object and indexed array are not guaranteed to be stable.
      class Diff
        attr_reader :raw, :diff_type, :type, :title, :structure

        # Public: Construct a OctocatalogDiff::API::V1::Diff object from many different types of
        # input. This includes passing a OctocatalogDiff::API::V1::Diff object and getting that
        # identical object back.
        # @param object_in [?] Object in
        # @return [OctocatalogDiff::API::V1::Diff] Object out
        def self.factory(object_in)
          return object_in if object_in.is_a?(OctocatalogDiff::API::V1::Diff)

          return new(object_in) if object_in.is_a?(Array)

          raise ArgumentError, "Cannot construct OctocatalogDiff::API::V1::Diff from #{object_in.class}"
        end

        # Constructor: Accepts a diff in the traditional array format and stores it.
        # @param raw [Array] Diff in the traditional format
        def initialize(raw)
          unless raw.is_a?(Array)
            raise ArgumentError, "OctocatalogDiff::API::V1::Diff#initialize expects Array argument (got #{raw.class})"
          end

          @raw = raw
          initialize_helper
        end

        # Public: Retrieve an indexed value from the array
        # @return [?] Indexed value
        def [](i)
          @raw[i]
        end

        # Public: Set an element of the array
        # @param [new_value] The value to set it to
        def []=(i, new_value)
          @raw[i] = new_value
        end

        # Public: Is this an addition?
        # @return [Boolean] True if this is an addition
        def addition?
          diff_type == '+'
        end

        # Public: Is this a removal?
        # @return [Boolean] True if this is an addition
        def removal?
          diff_type == '-'
        end

        # Public: Is this a change?
        # @return [Boolean] True if this is an change
        def change?
          diff_type == '~' || diff_type == '!'
        end

        # Public: Get the "old" value, i.e. "from" catalog
        # @return [?] "old" value
        def old_value
          return if addition?
          @raw[2]
        end

        # Public: Get the "new" value, i.e. "to" catalog
        # @return [?] "new" value
        def new_value
          return if removal?
          return @raw[2] if addition?
          @raw[3]
        end

        # Public: Get the filename from the "old" location
        # @return [String] Filename
        def old_file
          x = old_location
          x.nil? ? nil : x['file']
        end

        # Public: Get the line number from the "old" location
        # @return [String] Line number
        def old_line
          x = old_location
          x.nil? ? nil : x['line']
        end

        # Public: Get the filename from the "new" location
        # @return [String] Filename
        def new_file
          x = new_location
          x.nil? ? nil : x['file']
        end

        # Public: Get the line number from the "new" location
        # @return [String] Line number
        def new_line
          x = new_location
          x.nil? ? nil : x['line']
        end

        # Public: Get the "old" location, i.e. location in the "from" catalog
        # @return [Hash] <file:, line:> of resource
        def old_location
          return if addition?
          return @raw[3] if removal?
          @raw[4]
        end

        # Public: Get the "new" location, i.e. location in the "to" catalog
        # @return [Hash] <file:, line:> of resource
        def new_location
          return @raw[3] if addition?
          return if removal?
          @raw[5]
        end

        # Public: Convert this object to a hash
        # @return [Hash] Hash with keys set by these methods
        def to_h
          {
            diff_type: diff_type,
            type: type,
            title: title,
            structure: structure,
            old_value: old_value,
            new_value: new_value,
            old_file: old_file,
            old_line: old_line,
            new_file: new_file,
            new_line: new_line,
            old_location: old_location,
            new_location: new_location
          }
        end

        # Public: Convert this object to a hash with string keys
        # @return [Hash] Hash with keys set by these methods, with string keys
        def to_h_with_string_keys
          result = {}
          to_h.each { |key, val| result[key.to_s] = val }
          result
        end

        # Public: String inspection
        # @return [String] String for inspection
        def inspect
          to_h.inspect
        end

        # Public: To string
        # @return [String] Compact string representation
        def to_s
          raw.inspect
        end

        private

        # Private: Initialize further instance variables
        def initialize_helper
          unless ['+', '-', '~', '!'].include?(@raw[0])
            raise ArgumentError, 'Invalid first element array: diff type needs to be one of: +, -, ~, !'
          end
          @diff_type = @raw[0]

          unless @raw[1].is_a?(String)
            raise ArgumentError, "Invalid second element array: type-title-structure needs to be a string not #{@raw[1].class}"
          end
          raw_1_split = @raw[1].split(/\f/)
          @type = raw_1_split[0]
          @title = raw_1_split[1]
          @structure = raw_1_split[2..-1]
        end
      end
    end
  end
end
