# frozen_string_literal: true

require_relative '../catalog-util/facts'
require_relative '../external/pson/pure'
require_relative '../util/httparty'

require 'json'
require 'securerandom'
require 'stringio'

module OctocatalogDiff
  class Catalog
    # Represents a Puppet catalog that is obtained by contacting the Puppet Master.
    class PuppetMaster
      attr_accessor :node
      attr_reader :error_message, :catalog, :catalog_json, :convert_file_resources, :options, :retries

      # Defaults
      DEFAULT_PUPPET_PORT_NUMBER = 8140
      DEFAULT_PUPPET_SERVER_API = 3
      PUPPET_MASTER_TIMEOUT = 60

      # Constructor
      # @param :node [String] Node name
      # @param :retry_failed_catalog [Fixnum] Number of retries, if fetch fails
      # @param :branch [String] Environment to fetch from Puppet Master
      # @param :puppet_master [String] Puppet server and port number (assumed to be DEFAULT_PUPPET_PORT_NUMBER if not given)
      # @param :puppet_master_api_version [Fixnum] Puppet server API (default DEFAULT_PUPPET_SERVER_API)
      # @param :puppet_master_ssl_ca [String] Path to file used to sign puppet master's certificate
      # @param :puppet_master_ssl_verify [Boolean] Override the CA verification setting guessed from parameters
      # @param :puppet_master_ssl_client_pem [String] PEM-encoded client key and certificate
      # @param :puppet_master_ssl_client_p12 [String] pkcs12-encoded client key and certificate
      # @param :puppet_master_ssl_client_password [String] Path to file containing password for SSL client key (any format)
      # @param :puppet_master_ssl_client_auth [Boolean] Override the client-auth that is guessed from parameters
      # @param :timeout [Fixnum] Connection timeout for Puppet master (default=PUPPET_MASTER_TIMEOUT seconds)
      def initialize(options)
        raise ArgumentError, 'Hash of options must be passed to OctocatalogDiff::Catalog::PuppetMaster' unless options.is_a?(Hash)
        raise ArgumentError, 'node must be a non-empty string' unless options[:node].is_a?(String) && options[:node] != ''
        unless options[:branch].is_a?(String) && options[:branch] != ''
          raise ArgumentError, 'Environment must be a non-empty string'
        end
        unless options[:puppet_master].is_a?(String) && options[:puppet_master] != ''
          raise ArgumentError, 'Puppet Master must be a non-empty string'
        end

        @node = options[:node]
        @catalog = nil
        @error_message = nil
        @retries = nil
        @timeout = options.fetch(:puppet_master_timeout, options.fetch(:timeout, PUPPET_MASTER_TIMEOUT))
        @retry_failed_catalog = options.fetch(:retry_failed_catalog, 0)

        # Cannot convert file resources from this type of catalog right now.
        # FIXME: This is possible with additional API calls but is current unimplemented.
        @convert_file_resources = false

        options[:puppet_master] += ":#{DEFAULT_PUPPET_PORT_NUMBER}" unless options[:puppet_master] =~ /\:\d+$/
        @options = options
      end

      # Build method
      def build(logger = Logger.new(StringIO.new))
        facts_obj = OctocatalogDiff::CatalogUtil::Facts.new(@options, logger)
        logger.debug "Start retrieving facts for #{@node} from #{self.class}"
        @facts = facts_obj.facts
        logger.debug "Success retrieving facts for #{@node} from #{self.class}"
        fetch_catalog(logger)
      end

      private

      # Returns a hash of parameters for each supported version of the Puppet Server Catalog API.
      # @return [Hash] Hash of parameters
      #
      # Note: The double escaping of the facts here is implemented to correspond to a long standing
      # bug in the Puppet code. See https://github.com/puppetlabs/puppet/pull/1818 and
      # https://docs.puppet.com/puppet/latest/http_api/http_catalog.html#parameters for explanation.
      def puppet_catalog_api
        {
          2 => {
            url: "https://#{@options[:puppet_master]}/#{@options[:branch]}/catalog/#{@node}",
            parameters: {
              'facts_format' => 'pson',
              'facts' => CGI.escape(@facts.fudge_timestamp.without('trusted').to_pson),
              'transaction_uuid' => SecureRandom.uuid
            }
          },
          3 => {
            url: "https://#{@options[:puppet_master]}/puppet/v3/catalog/#{@node}",
            parameters: {
              'environment' => @options[:branch],
              'facts_format' => 'pson',
              'facts' => CGI.escape(@facts.fudge_timestamp.without('trusted').to_pson),
              'transaction_uuid' => SecureRandom.uuid
            }
          }
        }
      end

      # Fetch catalog by contacting the Puppet master, sending the facts, and asking for the catalog. When the
      # catalog is returned in PSON format, parse it to JSON and then set appropriate variables.
      def fetch_catalog(logger)
        api_version = @options[:puppet_master_api_version] || DEFAULT_PUPPET_SERVER_API
        api = puppet_catalog_api[api_version]
        raise ArgumentError, "Unsupported or invalid API version #{api_version}" unless api.is_a?(Hash)

        more_options = { headers: { 'Accept' => 'text/pson' }, timeout: @timeout }
        post_hash = api[:parameters]

        response = nil
        0.upto(@retry_failed_catalog) do |retry_num|
          @retries = retry_num
          logger.debug "Retrieve catalog from #{api[:url]} environment #{@options[:branch]}"

          response = OctocatalogDiff::Util::HTTParty.post(api[:url], @options.merge(more_options), post_hash, 'puppet_master')

          logger.debug "Response from #{api[:url]} environment #{@options[:branch]} was #{response[:code]}"

          break if response[:code] == 200
        end

        unless response[:code] == 200
          @error_message = "Failed to retrieve catalog from #{api[:url]}: #{response[:code]} #{response[:body]}"
          @catalog = nil
          @catalog_json = nil
          return
        end

        @catalog = response[:parsed]
        @catalog_json = ::JSON.generate(@catalog)
        @error_message = nil
      end
    end
  end
end
