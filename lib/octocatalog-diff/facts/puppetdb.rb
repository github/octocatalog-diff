# frozen_string_literal: true

require_relative '../errors'
require_relative '../facts'
require_relative '../puppetdb'
require 'yaml'

module OctocatalogDiff
  class Facts
    # Deal with facts in PuppetDB
    class PuppetDB
      # Supporting multiple versions of the PuppetDB API.
      PUPPETDB_QUERY_FACTS_URL = {
        '3' => '/v3/nodes/<NODE>/facts',
        '4' => '/pdb/query/v4/nodes/<NODE>/facts'
      }.freeze

      # Retrieve facts from PuppetDB for a specified node.
      # @param :puppetdb_url [String|Array] => URL to PuppetDB
      # @param :retry [Fixnum] => Retry after timeout (default 0 retries, can be more)
      # @param node [String] Node name. (REQUIRED for PuppetDB fact source)
      # @return [Hash] Facts
      def self.fact_retriever(options = {}, node)
        # Set up some variables from options
        raise ArgumentError, 'puppetdb_url is required' unless options[:puppetdb_url].is_a?(String)
        raise ArgumentError, 'node must be a non-empty string' unless node.is_a?(String) && node != ''
        puppetdb_api_version = options.fetch(:puppetdb_api_version, 4)
        uri = PUPPETDB_QUERY_FACTS_URL.fetch(puppetdb_api_version.to_s).gsub('<NODE>', node)
        retries = options.fetch(:retry, 0).to_i

        # Construct puppetdb object and options
        opts = options.merge(timeout: 5)
        puppetdb = OctocatalogDiff::PuppetDB.new(opts)

        # Use OctocatalogDiff::PuppetDB to pull facts
        exception_class = nil
        exception_message = nil
        obj_to_return = nil
        (retries + 1).times do
          begin
            result = puppetdb.get(uri)
            facts = {}
            result.map { |x| facts[x['name']] = x['value'] }
            if facts.empty?
              message = "Unable to retrieve facts for node #{node} from PuppetDB (empty or nil)!"
              raise OctocatalogDiff::Errors::FactRetrievalError, message
            end

            # Create a structure compatible with YAML fact files.
            obj_to_return = { 'name' => node, 'values' => {} }
            facts.each { |k, v| obj_to_return['values'][k.sub(/^::/, '')] = v }
            break # Not return, to avoid LocalJumpError in Ruby 2.2
          rescue OctocatalogDiff::Errors::PuppetDBConnectionError => exc
            exception_class = OctocatalogDiff::Errors::FactSourceError
            exception_message = "Fact retrieval failed (#{exc.class}) (#{exc.message})"
          rescue OctocatalogDiff::Errors::PuppetDBNodeNotFoundError => exc
            exception_class = OctocatalogDiff::Errors::FactRetrievalError
            exception_message = "Node #{node} not found in PuppetDB (#{exc.message})"
          rescue OctocatalogDiff::Errors::PuppetDBGenericError => exc
            exception_class = OctocatalogDiff::Errors::FactRetrievalError
            exception_message = "Fact retrieval failed for node #{node} from PuppetDB (#{exc.message})"
          end
        end
        return obj_to_return unless obj_to_return.nil?
        raise exception_class, exception_message
      end
    end
  end
end
