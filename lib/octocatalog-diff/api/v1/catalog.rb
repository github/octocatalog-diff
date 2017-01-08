# frozen_string_literal: true

require_relative 'common'
require_relative '../../catalog'

module OctocatalogDiff
  module API
    module V1
      # This is a wrapper class around OctocatalogDiff::Catalog. This contains the methods we
      # are choosing to expose, and will be a compatibility layer should underlying methods
      # change in the future. The raw object will be available as `#raw` but this is not
      # guaranteed to be stable.
      class Catalog
        attr_reader :raw

        # Constructor: Accepts a raw OctocatalogDiff::Catalog object and stores it.
        # @param raw [OctocatalogDiff::Catalog] Catalog object
        def initialize(raw)
          unless raw.is_a?(OctocatalogDiff::Catalog)
            raise ArgumentError, 'OctocatalogDiff::API::V1::Catalog#initialize expects OctocatalogDiff::Catalog argument'
          end
          @raw = raw
        end

        # Public: Get the builder for the catalog
        # @return [String] Class of backend used
        def builder
          @raw.builder
        end

        # Public: Get the JSON for the catalog
        # @return [String] Catalog JSON
        def to_json
          @raw.catalog_json
        end

        # Public: Get the compilation directory
        # @return [String] Compilation directory
        def compilation_dir
          @raw.compilation_dir
        end

        # Public: Get the error message
        # @return [String] Error message, or nil if no error
        def error_message
          @raw.error_message
        end

        # Public: Get the Puppet version used to compile the catalog
        # @return [String] Puppet version
        def puppet_version
          @raw.puppet_version
        end

        # Public: Get a specific resource identified by type and title.
        # This is intended for use when a O(1) lookup is required.
        # @param :type [String] Type of resource
        # @param :title [String] Title of resource
        # @return [Hash] Resource item
        def resource(opts = {})
          @raw.resource(opts)
        end

        # Public: Get the resources in the catalog
        # @return [Array] Resource array
        def resources
          @raw.resources
        end

        # Public: Determine if the catalog build was successful.
        # @return [Boolean] Whether the catalog is valid
        def valid?
          @raw.valid?
        end

        # Public: Return catalog as hash.
        # @return [Hash] Catalog as hash
        def to_h
          @raw.catalog
        end
      end
    end
  end
end
