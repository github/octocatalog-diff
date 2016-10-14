require 'json'

module OctocatalogDiff
  module CatalogDiff
    class Cli
      class Helpers
        # Since input from the command line is in the format of a string, this class helps to guess
        # at the data type.
        class FactOverride
          # Accessors
          attr_reader :key, :value

          # Constructor: Input will be a string (since it comes from command line).
          # This code will make a best guess at the data type (or use a supplied data type if any).
          # @param input [String] Input in the format: key=(data type)value
          def initialize(input, key = nil)
            # Normally the input will be a string in the format key=(data type)value where the data
            # type is optional and the parentheses are literal. Example:
            #   foo=1            (auto-determine data type - in this case it would be a fixnum)
            #   foo=(fixnum)1    (will be a fixnum)
            #   foo=(string)1    (will be '1' the string)
            # If input is not a string, we can still construct the object if the key is given.
            # That input would come directly from code and not from the command line, since inputs
            # from the command line are always strings.
            if input.is_a?(String)
              unless input.include?('=')
                raise ArgumentError, "Fact override '#{input}' is not in 'key=(data type)value' format"
              end
              input.strip!
              @key, raw_value = input.split('=', 2)
              @value = parsed_value(raw_value)
            elsif key.nil?
              message = "Define a key when the input is not a string (#{input.class} => #{input.inspect})"
              raise ArgumentError, message
            else
              @key = key
              @value = input
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
            if datatype == 'fixnum'
              return Regexp.last_match(1).to_i if value =~ /^(-?\d+)$/
              raise ArgumentError, "Illegal fixnum '#{value}'"
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
end
