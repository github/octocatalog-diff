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

        # Handle --ignore-tags option, the ability to tag resources within modules/manifests and
        # have catalog-diff ignore them.
        if @options[:ignore_tags].is_a?(Array) && @options[:ignore_tags].any?
          # Go through the "to" catalog and identify any resources that have been tagged with one or more
          # specified "ignore tags." Add any such items to the ignore list. The 'to' catalog has the authoritative
          # list of dynamic ignores.
          catalogs[:to].resources.each do |resource|
            next unless tagged_for_ignore?(resource)
            differ.ignore(type: resource['type'], title: resource['title'])
            @logger.debug "Ignoring type='#{resource['type']}', title='#{resource['title']}' based on tag in to-catalog"
          end

          # Go through the "from" catalog and identify any resources that have been tagged with one or more
          # specified "ignore tags." Only mark the resources for ignoring if they do not appear in the 'to'
          # catalog, thereby allowing the 'to' catalog to be the authoritative ignore list. This allows deleted
          # items that were previously ignored to continue to be ignored.
          catalogs[:from].resources.each do |resource|
            next if catalogs[:to].resource(type: resource['type'], title: resource['title'])
            next unless tagged_for_ignore?(resource)
            differ.ignore(type: resource['type'], title: resource['title'])
            @logger.debug "Ignoring type='#{resource['type']}', title='#{resource['title']}' based on tag in from-catalog"
          end
        end

        # Actually perform the diff
        diff_result = differ.diff
        @logger.debug 'Success compute diffs between catalogs'
        diff_result
      end

      private

      # Determine if a resource is tagged with any ignore-tag.
      # @param resource [Hash] The resource
      # @return [Boolean] true if tagged for ignore, false if not
      def tagged_for_ignore?(resource)
        return false unless @options[:ignore_tags].is_a?(Array)
        return false unless resource.key?('tags') && resource['tags'].is_a?(Array)
        @options[:ignore_tags].each do |tag|
          # tag_with_type will be like: 'ignored_catalog_diff__mymodule__mytype'
          tag_with_type = [tag, resource['type'].downcase.gsub(/\W/, '_')].join('__')
          return true if resource['tags'].include?(tag) || resource['tags'].include?(tag_with_type)
        end
        false
      end
    end
  end
end
