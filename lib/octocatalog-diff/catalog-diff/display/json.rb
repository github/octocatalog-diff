# frozen_string_literal: true

require_relative '../display'

require 'json'

module OctocatalogDiff
  module CatalogDiff
    class Display
      # Display the output from a diff in JSON format. This is the new format, used in octocatalog-diff
      # 1.x, where each diff is represented by an hash with named keys.
      class Json < OctocatalogDiff::CatalogDiff::Display
        # Generate JSON representation of the 'diff' suitable for further analysis.
        # @param diff [Array<Diff results>] The diff which *must* be in this format
        # @param options [Hash] Options which are:
        #           - :header => [String] Header to print; no header is printed if not specified
        # @param _logger [Logger] Not used here
        def self.generate(diff, options = {}, _logger = nil)
          result = {
            'diff' => diff.map(&:to_h_with_string_keys)
          }
          result['header'] = options[:header] unless options[:header].nil?
          result.to_json
        end
      end
    end
  end
end
