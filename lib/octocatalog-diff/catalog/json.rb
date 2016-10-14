require 'json'

module OctocatalogDiff
  class Catalog
    # Represents a Puppet catalog that is read in directly from a JSON file.
    class JSON
      attr_accessor :node
      attr_reader :error_message, :catalog, :catalog_json

      # Constructor
      # @param :json [String] REQUIRED: Content of catalog, will be parsed as JSON
      # @param :node [String] Node name (if not supplied, will be determined from catalog)
      def initialize(options)
        raise ArgumentError, 'Usage: OctocatalogDiff::Catalog::JSON.initialize(options_hash)' unless options.is_a?(Hash)
        raise ArgumentError, "Must supply :json as string in options: #{options[:json].class}" unless options[:json].is_a?(String)
        @catalog_json = options[:json]
        begin
          @catalog = ::JSON.parse(@catalog_json)
          @error_message = nil
          @node ||= @catalog['name'] if @catalog.key?('name') # Puppet 4.x
          @node ||= @catalog['data']['name'] if @catalog.key?('data') && @catalog['data'].is_a?(Hash) # Puppet 3.x
        rescue ::JSON::ParserError => exc
          @error_message = "Catalog JSON input failed to parse: #{exc.message}"
          @catalog = nil
          @catalog_json = nil
        end
      end
    end
  end
end
