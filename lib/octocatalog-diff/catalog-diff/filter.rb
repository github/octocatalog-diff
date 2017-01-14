require_relative 'filter/absent_file'
require_relative 'filter/compilation_dir'
require_relative 'filter/yaml'

require 'stringio'

module OctocatalogDiff
  module CatalogDiff
    # Filtering of diffs, and parent class for inheritance.
    class Filter
      attr_accessor :logger

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
        filter_class_name = [name.to_s, filter_class_name].join('::')
        obj = Kernel.const_get(filter_class_name).new(result, options[:logger])
        result.reject! { |item| obj.filtered?(item, options) }
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
