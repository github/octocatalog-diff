# frozen_string_literal: true

require_relative 'v1/catalog'
require_relative 'v1/catalog-compile'
require_relative 'v1/catalog-diff'
require_relative 'v1/config'
require_relative 'v1/diff'
require_relative 'v1/override'

module OctocatalogDiff
  module API
    # Call available methods for this version of the API
    module V1
      def self.catalog(options = nil)
        OctocatalogDiff::API::V1::CatalogCompile.catalog(options)
      end

      def self.catalog_diff(options = nil)
        OctocatalogDiff::API::V1::CatalogDiff.catalog_diff(options)
      end

      def self.config(options = nil)
        OctocatalogDiff::API::V1::Config.config(options)
      end
    end
  end
end
