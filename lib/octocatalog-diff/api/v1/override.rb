# frozen_string_literal: true

require 'json'

module OctocatalogDiff
  module API
    module V1
      # Sets up the override of a fact or ENC parameter during catalog compilation.
      class Override
        # Accessors
        attr_reader :key, :value

        # Constructor: Accepts a key and value.
        # @param input [Hash] Must contain :key and :value
        def initialize(input)
          key = input.fetch(:key)
          @key = key =~ %r{\A/(.+)/\Z} ? Regexp.new(Regexp.last_match(1)) : key
          @value = parsed_value(input.fetch(:value))
        end

        # Initialize from a parsed command line
        # @param input [String] Command line parameter
        # @return [OctocatalogDiff::API::V1::Override] Initialized object
        def self.create_from_input(input, key = nil)
          # Normally the input will be a string in the format key=(data type)value where the data
          # type is optional and the parentheses are literal. Example:
          #   foo=1            (auto-determine data type - in this case it would be a fixnum)
          #   foo=(fixnum)1    (will be a fixnum)
          #   foo=(string)1    (will be '1' the string)
          # If input is not a string, we can still construct the object if the key is given.
          # That input would come directly from code and not from the command line, since inputs
          # from the command line are always strings.
          # Also support regular expressions for the key name, if delimited by //.
          if key.nil? && input.is_a?(String)
            unless input.include?('=')
              raise ArgumentError, "Fact override '#{input}' is not in 'key=(data type)value' format"
            end
            k, v = input.strip.split('=', 2).map(&:strip)
            new(key: k, value: v)
          elsif key.nil?
            message = "Define a key when the input is not a string (#{input.class} => #{input.inspect})"
            raise ArgumentError, message
          else
            new(key: key, value: input)
          end
        end

        private

        # Guess the datatype from a particular input
        # @param input [String] Input in string format
        # @return [?] Output in appropriate format
        def parsed_value(input)
          # If data type is explicitly given
          if input =~ /^\((\w+)\)(.*)$/m
            datatype = Regexp.last_match(1)
            value = Regexp.last_match(2)
            return convert_to_data_type(datatype.downcase, value)
          end

          # Guess data type
          return input.to_i if input =~ /^-?\d+$/
          return input.to_f if input =~ /^-?\d*\.\d+$/
          return true if input.casecmp('true').zero?
          return false if input.casecmp('false').zero?
          input
        end

        # Handle data type that's explicitly given
        # @param datatype [String] Data type (as a string)
        # @param value [String] Value given
        # @return [?] Value converted to specified data type
        def convert_to_data_type(datatype, value)
          return value if datatype == 'string'
          return parse_json(value) if datatype == 'json'
          return nil if datatype == 'nil'
          if datatype == 'fixnum' || datatype == 'integer'
            return Regexp.last_match(1).to_i if value =~ /^(-?\d+)$/
            raise ArgumentError, "Illegal integer '#{value}'"
          end
          if datatype == 'float'
            return Regexp.last_match(1).to_f if value =~ /^(-?\d*\.\d+)$/
            return Regexp.last_match(1).to_f if value =~ /^(-?\d+)$/
            raise ArgumentError, "Illegal float '#{value}'"
          end
          if datatype == 'boolean'
            return true if value.casecmp('true').zero?
            return false if value.casecmp('false').zero?
            raise ArgumentError, "Illegal boolean '#{value}'"
          end
          raise ArgumentError, "Unknown data type '#{datatype}'"
        end

        # Parse JSON value
        # @param input [String] Input, hopefully in JSON format
        # @return [?] Output data structure
        def parse_json(input)
          JSON.parse(input)
        rescue JSON::ParserError => exc
          raise JSON::ParserError, "Failed to parse JSON: input=#{input} error=#{exc}"
        end
      end
    end
  end
end
