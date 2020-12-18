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
      # @param :retry [Integer] => Retry after timeout (default 0 retries, can be more)
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
        packages = nil
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

        raise exception_class, exception_message if obj_to_return.nil?

        return obj_to_return if puppetdb_api_version < 4 || (!options[:puppetdb_package_inventory])

        (retries + 1).times do
          begin
            result = puppetdb.get("/pdb/query/v4/package-inventory/#{node}")
            packages = {}
            result.each do |pkg|
              key = "#{pkg['package_name']}+#{pkg['provider']}"
              # Need to handle the situation where a package has multiple versions installed.
              # The _puppet_inventory_1 hash lists them separated by "; ".
              if packages.key?(key)
                packages[key]['version'] += "; #{pkg['version']}"
              else
                packages[key] = pkg
              end
            end
            break
          rescue OctocatalogDiff::Errors::PuppetDBConnectionError => exc
            exception_class = OctocatalogDiff::Errors::FactSourceError
            exception_message = "Package inventory retrieval failed (#{exc.class}) (#{exc.message})"
          # This is not expected to occur, but we'll leave it just in case. A query to package-inventory
          # for a non-existant node returns a 200 OK with an empty list of packages:
          rescue OctocatalogDiff::Errors::PuppetDBNodeNotFoundError
            packages = {}
          rescue OctocatalogDiff::Errors::PuppetDBGenericError => exc
            exception_class = OctocatalogDiff::Errors::FactRetrievalError
            exception_message = "Package inventory retrieval failed for node #{node} from PuppetDB (#{exc.message})"
          end
        end

        raise exception_class, exception_message if packages.nil?

        unless packages.empty?
          obj_to_return['values']['_puppet_inventory_1'] = {
            'packages' => packages.values.map { |pkg| [pkg['package_name'], pkg['version'], pkg['provider']] }
          }
        end

        obj_to_return
      end
    end
  end
end
