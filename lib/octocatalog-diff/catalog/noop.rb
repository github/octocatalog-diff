require 'json'

module OctocatalogDiff
  class Catalog
    # Represents a null Puppet catalog.
    class Noop
      attr_accessor :node
      attr_reader :error_message, :catalog, :catalog_json

      # Constructor
      def initialize(options)
        @catalog_json = '{"resources":[]}'
        @catalog = { 'resources' => [] }
        @error_message = nil
        @node = options.fetch(:node, 'noop')
      end
    end
  end
end
