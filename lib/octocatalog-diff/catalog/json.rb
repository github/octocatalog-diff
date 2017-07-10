# frozen_string_literal: true

require_relative '../catalog'
require_relative '../catalog-util/fileresources'

require 'json'

module OctocatalogDiff
  class Catalog
    # Represents a Puppet catalog that is read in directly from a JSON file.
    class JSON < OctocatalogDiff::Catalog
      # Constructor
      # @param :json [String] REQUIRED: Content of catalog, will be parsed as JSON
      # @param :node [String] Node name (if not supplied, will be determined from catalog)
      def initialize(options)
        super

        unless options[:json].is_a?(String)
          raise ArgumentError, "Must supply :json as string in options: #{options[:json].class}"
        end

        @catalog_json = options.fetch(:json)
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

      # Convert file resources source => "puppet:///..." to content => "actual content of file".
      def convert_file_resources(dry_run = false)
        return @options.key?(:basedir) if dry_run
        return false unless @options[:basedir]
        OctocatalogDiff::CatalogUtil::FileResources.convert_file_resources(self, environment)
      end
    end
  end
end
