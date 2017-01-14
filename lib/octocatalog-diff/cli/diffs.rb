# frozen_string_literal: true

require_relative '../catalog-diff/differ'

module OctocatalogDiff
  class Cli
    # Wrapper around OctocatalogDiff::CatalogDiff::Differ to provide the logger object, set up
    # ignores, and add additional ignores for items dependent upon the compilation directory.
    class Diffs
      # Constructor
      # @param options [Hash] Options from cli/options
      # @param logger [Logger] Logger object
      def initialize(options, logger)
        @options = options
        @logger = logger
      end

      # The method to call externally, passing in the catalogs as a hash (see parameter). This
      # sets up options and ignores and then actually performs the diffs. The result is the array
      # of diffs.
      # @param catalogs [Hash] { :to => OctocatalogDiff::Catalog, :from => OctocatalogDiff::Catalog }
      # @return [Array<diffs>] Array of diffs
      def diffs(catalogs)
        @logger.debug 'Begin compute diffs between catalogs'
        diff_opts = @options.merge(logger: @logger)

        # Construct the actual differ object that the present one wraps
        differ = OctocatalogDiff::CatalogDiff::Differ.new(diff_opts, catalogs[:from], catalogs[:to])
        differ.ignore(attr: 'tags') unless @options.fetch(:include_tags, false)
        differ.ignore(@options.fetch(:ignore, []))
        differ.ignore_tags

        # Actually perform the diff
        diff_result = differ.diff
        @logger.debug 'Success compute diffs between catalogs'
        diff_result
      end
    end
  end
end
