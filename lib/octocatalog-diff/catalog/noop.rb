# frozen_string_literal: true

require_relative '../catalog'

require 'json'

module OctocatalogDiff
  class Catalog
    # Represents a null Puppet catalog.
    class Noop < OctocatalogDiff::Catalog
      def initialize(options)
        super

        @catalog_json = '{"resources":[]}'
        @catalog = { 'resources' => [] }
        @error_message = nil
        @node = options.fetch(:node, 'noop')
      end
    end
  end
end
