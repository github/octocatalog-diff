# frozen_string_literal: true

require 'set'

module OctocatalogDiff
  module CatalogDiff
    class Filter
      # Filter out changes in parameters when the "to" resource has ensure => absent.
      class AbsentFile < OctocatalogDiff::CatalogDiff::Filter
        # Constructor: Since this filter requires knowledge of the entire array of diffs,
        # override the inherited method to store those diffs in an instance variable.
        def initialize(diffs)
          @diffs = diffs
          @results = nil
        end

        # Public: If a file has ensure => absent, there are certain parameters that don't
        # matter anymore. Filter out any such parameters from the result array.
        # Return true if the difference is in a resource where `ensure => absent` has been
        # declared. Return false if they this is not the case.
        #
        # @param diff [internal diff format] Difference
        # @param _options [Hash] Additional options (there are none for this filter)
        # @return [Boolean] true if this difference is a YAML file with identical objects, false otherwise
        def filtered?(diff, _options = {})
          build_results if @results.nil?
          @results.include?(diff)
        end

        private

        # Private: The first time `.filtered?` is called, build up the cache of results.
        # Returns nothing, but populates @results.
        def build_results
          # Which files can we ignore?
          @files_to_ignore = Set.new
          @diffs.each do |diff|
            next unless diff[0] == '~' || diff[0] == '!'
            next unless diff[1] =~ /^File\f([^\f]+)\fparameters\fensure$/
            next unless ['absent', 'false', false].include?(diff[3])
            @files_to_ignore.add Regexp.last_match(1)
          end

          # Based on that, which diffs can we ignore?
          @results = Set.new @diffs.reject { |diff| keep_diff?(diff) }
        end

        # Private: Determine whether to keep a particular diff.
        # @param diff [OctocatalogDiff::API::V1::Diff] Difference under consideration
        # @return [Boolean] true = keep, false = discard
        def keep_diff?(diff)
          keep = %w(ensure backup force provider)
          if (diff[0] == '!' || diff[0] == '~') && diff[1] =~ /^File\f(.+)\fparameters\f(.+)$/
            if @files_to_ignore.include?(Regexp.last_match(1)) && !keep.include?(Regexp.last_match(2))
              return false
            end
          end
          true
        end
      end
    end
  end
end
