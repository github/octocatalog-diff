# frozen_string_literal: true

require_relative 'catalog'
require_relative 'common'
require_relative '../../util/catalogs'

module OctocatalogDiff
  module API
    module V1
      # This class allows octocatalog-diff to be used to compile catalogs.
      class CatalogCompile
        # Public: Compile a catalog given the options provided.
        #
        # Parameters are to be passed in a hash.
        # @param :logger [Logger] Logger object (be sure to configure log level)
        # @param :node [String] Node name (FQDN)
        # Other catalog building parameters are also accepted
        # @return [OctocatalogDiff::Catalog] Compiled catalogs

        def self.catalog(options = nil)
          # Validate the required options.
          unless options.is_a?(Hash)
            raise ArgumentError, 'Usage: #catalog(options_hash)'
          end

          pass_opts, logger = OctocatalogDiff::API::V1::Common.logger_from_options(options)
          logger.debug "Compiling catalog for #{options[:node]}"

          # Compile catalog
          catalog_opts = pass_opts.merge(
            from_catalog: '-', # Prevents a compile
            to_catalog: nil, # Forces a compile
          )
          cat_obj = OctocatalogDiff::Util::Catalogs.new(catalog_opts, logger)
          OctocatalogDiff::API::V1::Catalog.new(cat_obj.catalogs[:to])
        end
      end
    end
  end
end
