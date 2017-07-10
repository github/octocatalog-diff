# frozen_string_literal: true

require 'json'
require 'stringio'

require_relative '../catalog'
require_relative '../errors'
require_relative '../puppetdb'

module OctocatalogDiff
  class Catalog
    # Represents a Puppet catalog that is read from PuppetDB.
    class PuppetDB < OctocatalogDiff::Catalog
      # Constructor - See OctocatalogDiff::PuppetDB for additional parameters
      # @param :node [String] Node name
      # @param :retry [Integer] Number of retries, if fetch fails
      def initialize(options)
        super

        unless @options[:node].is_a?(String) && @options[:node] != ''
          raise ArgumentError, 'node must be a non-empty string'
        end
      end

      private

      # Private method: Get catalog from PuppetDB. Sets @catalog / @catalog_json or @error_message
      # @param logger [Logger object] Logger object
      def build_catalog(logger)
        # Use OctocatalogDiff::PuppetDB to interact with puppetdb
        puppetdb_obj = OctocatalogDiff::PuppetDB.new(@options)

        # Loop to retrieve catalog from PuppetDB
        uri = "/pdb/query/v4/catalogs/#{@node}"
        retries = @options.fetch(:retry, 1)
        (retries + 1).times do
          @retries = -1 if @retries.nil?
          @retries += 1
          begin
            # Fetch catalog from PuppetDB
            logger.debug "Retrieving #{@node} from #{uri}"
            time_start = Time.now
            result = puppetdb_obj.get(uri)
            time_it_took = Time.now - time_start

            # Validate received catalog
            raise "PuppetDB catalog for #{@node} failed: no 'resources' hash in object" unless result.key?('resources')
            raise "PuppetDB catalog for #{@node} failed: 'resources' was not a hash" unless result['resources'].is_a?(Hash)
            logger.debug "Catalog for #{@node} retrieved from PuppetDB in #{time_it_took} seconds"

            # Make this look like a generated catalog in Puppet 4.x
            @catalog = result.merge('resources' => result['resources']['data'])
            @catalog['resources'] = @catalog['resources'].map { |x| x.reject { |k, _v| k == 'resource' } }

            # Set the other variables
            @catalog_json = ::JSON.generate(@catalog)
            @error_message = nil
          rescue OctocatalogDiff::Errors::PuppetDBConnectionError => exc
            @error_message = "Catalog retrieval failed (#{exc.class}) (#{exc.message})"
          rescue OctocatalogDiff::Errors::PuppetDBNodeNotFoundError => exc
            @error_message = "Node #{node} not found in PuppetDB (#{exc.message})"
          rescue OctocatalogDiff::Errors::PuppetDBGenericError => exc
            @error_message = "Catalog retrieval failed for node #{node} from PuppetDB (#{exc.message})"
          rescue ::JSON::GeneratorError => exc
            @error_message = "Failed to generate result from PuppetDB as JSON (#{exc.message})"
          end
          break if @catalog
        end
      end
    end
  end
end
