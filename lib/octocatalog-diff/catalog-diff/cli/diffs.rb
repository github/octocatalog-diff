# frozen_string_literal: true

require_relative '../differ'

module OctocatalogDiff
  module CatalogDiff
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
          diff_result.delete_if { |element| change_due_to_compilation_dir?(element, catalogs) }
          @logger.debug 'Success compute diffs between catalogs'
          diff_result
        end

        # Catch anything that explictly changed as a result of different compilation directories and
        # warn about it. These are probably things that should be refactored. For now we're going to pull
        # these out after the fact so we can warn about them if they do show up.
        # @param change [Array(diff format)] Change in diff format
        # @param catalogs [Hash] { :to => OctocatalogDiff::Catalog, :from => OctocatalogDiff::Catalog }
        # @return [Boolean] True if change includes compilation directory, false otherwise
        def change_due_to_compilation_dir?(change, catalogs)
          dir1 = catalogs.fetch(:to).compilation_dir
          dir2 = catalogs.fetch(:from).compilation_dir
          return false if dir1.nil? || dir2.nil?

          dir1_rexp = Regexp.escape(dir1)
          dir2_rexp = Regexp.escape(dir2)
          dir = "(?:#{dir1_rexp}|#{dir2_rexp})"

          # Check for added/removed resources where the title of the resource includes the compilation directory
          if change[0] == '+' || change[0] == '-'
            if change[1] =~ /^([^\f]+)\f([^\f]*#{dir}[^\f]*)/
              message = "Resource #{Regexp.last_match(1)}[#{Regexp.last_match(2)}]"
              message += ' appears to depend on catalog compilation directory. Suppressed from results.'
              @logger.warn message
              return true
            end
          end

          # Check for a change where the difference in a parameter exactly corresponds to the difference in the
          # compilation directory.
          if change[0] == '~' || change[0] == '!'
            from_before = nil
            from_after = nil
            from_match = false
            to_before = nil
            to_after = nil
            to_match = false

            if change[2] =~ /^(.*)#{dir2}(.*)$/m
              from_before = Regexp.last_match(1) || ''
              from_after = Regexp.last_match(2) || ''
              from_match = true
            end

            if change[3] =~ /^(.*)#{dir1}(.*)$/m
              to_before = Regexp.last_match(1) || ''
              to_after = Regexp.last_match(2) || ''
              to_match = true
            end

            if from_match && to_match && to_before == from_before && to_after == from_after
              message = "Resource key #{change[1].gsub(/\f/, ' => ')}"
              message += ' appears to depend on catalog compilation directory. Suppressed from results.'
              @logger.warn message
              return true
            end

            if from_match || to_match
              message = "Resource key #{change[1].gsub(/\f/, ' => ')}"
              message += ' may depend on catalog compilation directory, but there may be differences.'
              message += ' This is included in results for now, but please verify.'
              @logger.warn message
            end
          end

          false
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
end
