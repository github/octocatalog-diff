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
      # easier to deal with.
      class Diff
        attr_reader :raw

        # Constructor: Accepts a diff in the traditional array format and stores it.
        # @param raw [Array] Diff in the traditional format
        def initialize(raw)
          unless raw.is_a?(Array)
            raise ArgumentError, 'OctocatalogDiff::API::V1::Diff#initialize expects Array argument'
          end
          @raw = raw
        end

        # Public: Retrieve an indexed value from the array
        # @return [?] Indexed value
        def [](i)
          @raw[i]
        end

        # Public: Get the change type
        # @return [String] Change type symbol (~, !, +, -)
        def change_type
          @raw[0]
        end

        # Public: Get the change type (English word)
        # @return [String] Change type word
        def change_type_word
          return 'change' if @raw[0] == '!' || @raw[0] == '~'
          return 'addition' if @raw[0] == '+'
          return 'removal' if @raw[0] == '-'
          raise ArgumentError, "No change type corresponds to #{@raw[0].inspect}"
        end

        # Public: Get the type_title string
        # @return [?] Type_title_structure
        def type_title
          @raw[1]
        end

        # Public: Get the resource type
        # @return [String] Resource type
        def type
          @raw[1].split(/\f/)[0]
        end

        # Public: Get the resource title
        # @return [String] Resource title
        def title
          @raw[1].split(/\f/)[1]
        end

        # Public: Get the structure of the resource as an array
        # @return [Array] Structure of resource
        def structure
          @raw[1].split(/\f/)[2..-1]
        end

        # Public: Get the "old" value, i.e. "from" catalog
        # @return [?] "old" value
        def old_value
          return nil if @raw[0] == '+'
          @raw[2]
        end

        # Public: Get the "new" value, i.e. "to" catalog
        # @return [?] "old" value
        def new_value
          return nil if @raw[0] == '-'
          return @raw[2] if @raw[0] == '+'
          @raw[3]
        end

        # Public: Get the "old" location, i.e. location in the "from" catalog
        # @return [Hash] <file:, line:> of resource
        def old_location
          return nil if @raw[0] == '+'
          return @raw[3] if @raw[0] == '-'
          @raw[4]
        end

        # Public: Get the "new" location, i.e. location in the "to" catalog
        # @return [Hash] <file:, line:> of resource
        def new_location
          return @raw[3] if @raw[0] == '+'
          return nil if @raw[0] == '-'
          @raw[5]
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
      end
    end
  end
end
