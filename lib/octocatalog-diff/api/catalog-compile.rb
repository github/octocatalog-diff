# frozen_string_literal: true

require_relative '../util/catalogs'

module OctocatalogDiff
  module API
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
          raise ArgumentError, 'Usage: OctocatalogDiff::API::CatalogCompile.catalog(options_hash)'
        end

        # If logger is not provided, create an object that can have messages written to it.
        # There won't be a way to access these messages, so if you want to log messages, then
        # provide that logger!
        logger = options[:logger] || Logger.new(StringIO.new)

        # Indicate where we are
        logger.debug "Compiling catalog for #{options[:node]}"

        # Compile catalog
        catalog_opts = options.merge(
          from_catalog: '-', # Prevents a compile
          to_catalog: nil, # Forces a compile
        )
        cat_obj = OctocatalogDiff::Util::Catalogs.new(catalog_opts, logger)
        cat_obj.catalogs[:to]
      end
    end
  end
end
