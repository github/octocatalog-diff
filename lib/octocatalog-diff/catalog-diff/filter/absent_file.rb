# frozen_string_literal: true

require_relative '../filter'

require 'set'

module OctocatalogDiff
  module CatalogDiff
    class Filter
      # Filter out changes in parameters when the "to" resource has ensure => absent.
      class AbsentFile < OctocatalogDiff::CatalogDiff::Filter
        KEEP_ATTRIBUTES = (Set.new %w(ensure backup force provider)).freeze
        ABSENT_VALUES = ['absent', 'false', false].freeze

        # Constructor: Since this filter requires knowledge of the entire array of diffs,
        # override the inherited method to store those diffs in an instance variable.
        # @param diffs [Array<OctocatalogDiff::API::V1::Diff>] Difference array
        # @param _logger [?] Ignored
        def initialize(diffs, _logger = nil)
          @diffs = diffs
          @results = nil
        end

        # Public: If a file has ensure => absent, there are certain parameters that don't
        # matter anymore. Filter out any such parameters from the result array.
        # Return true if the difference is in a resource where `ensure => absent` has been
        # declared. Return false if they this is not the case.
        #
        # @param diff [OctocatalogDiff::API::V1::Diff] Difference
        # @param _options [Hash] Additional options (there are none for this filter)
        # @return [Boolean] true if this difference is a YAML file with identical objects, false otherwise
        def filtered?(diff, options = {})
          build_results(options) if @results.nil?
          @results.include?(diff)
        end

        private

        # Private: The first time `.filtered?` is called, build up the cache of results.
        # Returns nothing, but populates @results.
        def build_results(options)
          @files_absent_in_to = Set.new
          @files_absent_in_from = Set.new

          if options[:to_resources].is_a?(Array)
            options[:to_resources].each do |resource|
              next unless resource.is_a?(Hash) && resource['type'] == 'File'
              next unless resource.key?('parameters') && resource['parameters'].is_a?(Hash)
              next unless ABSENT_VALUES.include?(resource['parameters']['ensure'])
              @files_absent_in_to.add file_title_for_resource(resource)
            end
          end

          if options[:from_resources].is_a?(Array)
            options[:from_resources].each do |resource|
              next unless resource.is_a?(Hash) && resource['type'] == 'File'
              next unless resource.key?('parameters') && resource['parameters'].is_a?(Hash)
              next unless ABSENT_VALUES.include?(resource['parameters']['ensure'])
              @files_absent_in_from.add file_title_for_resource(resource)
            end
          end

          # Backward-compatible behavior: if an ensure diff explicitly shows ensure => absent in the new
          # catalog, make sure we ignore that file even if resource lists were not provided.
          @diffs.each do |diff|
            next unless diff.change? && diff.type == 'File' && diff.structure == %w(parameters ensure)
            next unless ABSENT_VALUES.include?(diff.new_value)
            @files_absent_in_to.add diff.title
          end

          @files_absent_in_both = @files_absent_in_to & @files_absent_in_from

          # Based on that, which diffs can we ignore?
          @results = Set.new @diffs.reject { |diff| keep_diff?(diff) }
        end

        def file_title_for_resource(resource)
          return resource['title'] unless resource.key?('parameters') && resource['parameters'].is_a?(Hash)
          return resource['title'] unless resource['parameters'].key?('path')

          resource['parameters']['path']
        end

        # Private: Determine whether to keep a particular diff.
        # @param diff [OctocatalogDiff::API::V1::Diff] Difference under consideration
        # @return [Boolean] true = keep, false = discard
        def keep_diff?(diff)
          return true unless diff.change? && diff.type == 'File'

          # If both catalogs declare the same file as absent, suppress all diffs for that file.
          return false if @files_absent_in_both.include?(diff.title)

          return true unless diff.structure.first == 'parameters'
          return true unless @files_absent_in_to.include?(diff.title)
          return true if KEEP_ATTRIBUTES.include?(diff.structure.last)
          false
        end
      end
    end
  end
end
