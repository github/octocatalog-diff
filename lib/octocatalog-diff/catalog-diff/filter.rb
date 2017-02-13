require_relative '../api/v1/diff'
require_relative 'filter/absent_file'
require_relative 'filter/compilation_dir'
require_relative 'filter/json'
require_relative 'filter/yaml'

require 'stringio'

module OctocatalogDiff
  module CatalogDiff
    # Filtering of diffs, and parent class for inheritance.
    class Filter
      attr_accessor :logger

      # List the available filters here (by class name) for use in the validator method.
      AVAILABLE_FILTERS = %w(AbsentFile CompilationDir JSON YAML).freeze

      # Public: Determine whether a particular filter exists. This can be used to validate
      # a user-submitted filter.
      # @param filter_name [String] Proposed filter name
      # @return [Boolean] True if filter is valid; false otherwise
      def self.filter?(filter_name)
        AVAILABLE_FILTERS.include?(filter_name)
      end

      # Public: Assert that a filter exists, and raise an error if it does not.
      # @param filter_name [String] Proposed filter name
      def self.assert_that_filter_exists(filter_name)
        return if filter?(filter_name)
        raise ArgumentError, "The filter #{filter_name} is not valid"
      end

      # Public: Apply multiple filters by repeatedly calling the `filter` method for each
      # filter in an array. This method returns nothing.
      #
      # @param result [Array] Difference array (mutated)
      # @param filter_names [Array] Filters to run
      # @param options [Hash] Options for each filter
      def self.apply_filters(result, filter_names, options = {})
        return unless filter_names.is_a?(Array)
        filter_names.each { |x| filter(result, x, options || {}) }
      end

      # Public: Perform a filter on `result` using the specified filter class.
      # This mutates `result` by removing items that are ignored. This method
      # returns nothing.
      #
      # @param result [Array] Difference array (mutated)
      # @param filter_class_name [String] Filter class name (from `filter` subdirectory)
      # @param options [Hash] Additional options (optional) to pass to filtered? method
      def self.filter(result, filter_class_name, options = {})
        assert_that_filter_exists(filter_class_name)
        filter_class_name = [name.to_s, filter_class_name].join('::')

        # Need to convert each of the results array to the OctocatalogDiff::API::V1::Diff object, if
        # it isn't already. The comparison is done on that array which is then applied back to the
        # original array.
        result_hash = {}
        result.each { |x| result_hash[x] = OctocatalogDiff::API::V1::Diff.factory(x) }
        obj = Kernel.const_get(filter_class_name).new(result_hash.values, options[:logger])
        result.reject! { |item| obj.filtered?(result_hash[item], options) }
      end

      # Inherited: Constructor. Some filters require working on the entire data set and
      # will override this method to perform some pre-processing for efficiency. This also
      # sets up the logger object.
      def initialize(_diff_array = [], logger = Logger.new(StringIO.new))
        @logger = logger
      end

      # Inherited: Construct a default `filtered?` method for the subclass via inheritance.
      # Each subclass must implement this method, so the default method errors.
      def filtered?(_item, _options = {})
        raise "No `filtered?` method is implemented in #{self.class}"
      end
    end
  end
end
