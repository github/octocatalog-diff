# frozen_string_literal: true

require_relative 'catalog'
require_relative 'common'
require_relative 'diff'
require_relative '../../util/catalogs'
require_relative '../../catalog-util/cached_master_directory'

require 'ostruct'

module OctocatalogDiff
  module API
    module V1
      # This class allows octocatalog-diff to be used to compile catalogs (if needed)
      # and then compute the differences between them.
      class CatalogDiff
        # Public: Run catalog-diff
        #
        # Parameters are to be passed in a hash.
        # @param :logger [Logger] Logger object (be sure to configure log level)
        # Other catalog-diff parameters are required
        # @return [OpenStruct] { :diffs (Array); :from (OctocatalogDiff::Catalog), :to (OctocatalogDiff::Catalog) }
        def self.catalog_diff(options = nil)
          # Validate the required options.
          unless options.is_a?(Hash)
            raise ArgumentError, 'Usage: #catalog_diff(options_hash)'
          end

          pass_opts, logger = OctocatalogDiff::API::V1::Common.logger_from_options(options)

          # Compile catalogs
          logger.debug "Compiling catalogs for #{options[:node]}"
          catalogs_obj = OctocatalogDiff::Util::Catalogs.new(pass_opts, logger)
          catalogs = catalogs_obj.catalogs
          logger.info "Catalogs compiled for #{options[:node]}"

          # Cache catalogs if master caching is enabled. If a catalog is being read from the cached master
          # directory, set the compilation directory attribute, so that the "compilation directory dependent"
          # suppressor will still work.
          %w(from to).each do |x|
            next unless options["#{x}_env".to_sym] == options.fetch(:master_cache_branch, 'origin/master')
            next if options[:cached_master_dir].nil?
            catalogs[x.to_sym].compilation_dir = options["#{x}_catalog_compilation_dir".to_sym] || options[:cached_master_dir]
            rc = OctocatalogDiff::CatalogUtil::CachedMasterDirectory.save_catalog_in_cache_dir(
              options[:node],
              options[:cached_master_dir],
              catalogs[x.to_sym]
            )
            logger.debug "Cached master catalog for #{options[:node]}" if rc
          end

          # Compute diffs
          diffs_obj = OctocatalogDiff::Cli::Diffs.new(options, logger)
          diffs = diffs_obj.diffs(catalogs)
          logger.info "Diffs computed for #{options[:node]}"
          logger.info 'No differences' if diffs.empty?

          # Return diffs and catalogs in expected format
          OpenStruct.new(
            diffs: diffs.map { |x| OctocatalogDiff::API::V1::Diff.factory(x) },
            from: OctocatalogDiff::API::V1::Catalog.new(catalogs[:from]),
            to: OctocatalogDiff::API::V1::Catalog.new(catalogs[:to])
          )
        end
      end
    end
  end
end
