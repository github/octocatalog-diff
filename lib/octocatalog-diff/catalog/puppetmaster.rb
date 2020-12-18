# frozen_string_literal: true

require_relative '../catalog'
require_relative '../catalog-util/facts'
require_relative '../external/pson/pure'
require_relative '../util/httparty'

require 'json'
require 'securerandom'
require 'stringio'

module OctocatalogDiff
  class Catalog
    # Represents a Puppet catalog that is obtained by contacting the Puppet Master.
    class PuppetMaster < OctocatalogDiff::Catalog
      # Defaults
      DEFAULT_PUPPET_PORT_NUMBER = 8140
      DEFAULT_PUPPET_SERVER_API = 3
      PUPPET_MASTER_TIMEOUT = 60

      # Constructor
      # @param :node [String] Node name
      # @param :retry_failed_catalog [Integer] Number of retries, if fetch fails
      # @param :branch [String] Environment to fetch from Puppet Master
      # @param :puppet_master [String] Puppet server and port number (assumed to be DEFAULT_PUPPET_PORT_NUMBER if not given)
      # @param :puppet_master_api_version [Integer] Puppet server API (default DEFAULT_PUPPET_SERVER_API)
      # @param :puppet_master_ssl_ca [String] Path to file used to sign puppet master's certificate
      # @param :puppet_master_ssl_verify [Boolean] Override the CA verification setting guessed from parameters
      # @param :puppet_master_ssl_client_pem [String] PEM-encoded client key and certificate
      # @param :puppet_master_ssl_client_p12 [String] pkcs12-encoded client key and certificate
      # @param :puppet_master_ssl_client_password [String] Path to file containing password for SSL client key (any format)
      # @param :puppet_master_ssl_client_auth [Boolean] Override the client-auth that is guessed from parameters
      # @param :timeout [Integer] Connection timeout for Puppet master (default=PUPPET_MASTER_TIMEOUT seconds)
      def initialize(options)
        super

        unless @options[:node].is_a?(String) && @options[:node] != ''
          raise ArgumentError, 'node must be a non-empty string'
        end

        unless @options[:branch].is_a?(String) && @options[:branch] != ''
          raise ArgumentError, 'Environment must be a non-empty string'
        end

        unless @options[:puppet_master].is_a?(String) && @options[:puppet_master] != ''
          raise ArgumentError, 'Puppet Master must be a non-empty string'
        end

        @timeout = options.fetch(:puppet_master_timeout, options.fetch(:timeout, PUPPET_MASTER_TIMEOUT))
        @retry_failed_catalog = options.fetch(:retry_failed_catalog, 0)
        @options[:puppet_master] += ":#{DEFAULT_PUPPET_PORT_NUMBER}" unless @options[:puppet_master] =~ /\:\d+$/
      end

      private

      # Build method
      def build_catalog(logger = Logger.new(StringIO.new))
        facts_obj = OctocatalogDiff::CatalogUtil::Facts.new(@options, logger)
        logger.debug "Start retrieving facts for #{@node} from #{self.class}"
        @facts = facts_obj.facts
        logger.debug "Success retrieving facts for #{@node} from #{self.class}"
        fetch_catalog(logger)
      end

      # Returns a hash of parameters for the requested version of the Puppet Server Catalog API.
      # @return [Hash] Hash of parameters
      #
      # Note: The double escaping of the facts here is implemented to correspond to a long standing
      # bug in the Puppet code. See https://github.com/puppetlabs/puppet/pull/1818 and
      # https://docs.puppet.com/puppet/latest/http_api/http_catalog.html#parameters for explanation.
      def puppet_catalog_api(version)
        api_style = {
          2 => {
            url: "https://#{@options[:puppet_master]}/#{@options[:branch]}/catalog/#{@node}",
            headers: {
              'Accept' => 'text/pson'
            },
            parameters: {
              'facts_format' => 'pson',
              'facts' => CGI.escape(@facts.fudge_timestamp.without('trusted').to_pson),
              'transaction_uuid' => SecureRandom.uuid
            }
          },
          3 => {
            url: "https://#{@options[:puppet_master]}/puppet/v3/catalog/#{@node}",
            headers: {
              'Accept' => 'text/pson'
            },
            parameters: {
              'environment' => @options[:branch],
              'facts_format' => 'pson',
              'facts' => CGI.escape(@facts.fudge_timestamp.without('trusted').to_pson),
              'transaction_uuid' => SecureRandom.uuid
            }
          },
          4 => {
            url: "https://#{@options[:puppet_master]}/puppet/v4/catalog",
            headers: {
              'Content-Type' => 'application/json'
            },
            parameters: {
              'certname' => @node,
              'persistence' => {
                'facts' => @options[:puppet_master_update_facts] || false,
                'catalog' => @options[:puppet_master_update_catalog] || false
              },
              'environment' => @options[:branch],
              'facts' => { 'values' => @facts.facts['values'] },
              'options' => {
                'prefer_requested_environment' => true,
                'capture_logs' => false,
                'log_level' => 'warning'
              },
              'transaction_uuid' => SecureRandom.uuid
            }
          }
        }

        params = api_style[version]
        return nil if params.nil?

        unless @options[:puppet_master_token].nil?
          params[:headers]['X-Authentication'] = @options[:puppet_master_token]
        end

        params[:parameters] = params[:parameters].to_json if version >= 4

        params
      end

      # Fetch catalog by contacting the Puppet master, sending the facts, and asking for the catalog. When the
      # catalog is returned in PSON format, parse it to JSON and then set appropriate variables.
      def fetch_catalog(logger)
        api_version = @options[:puppet_master_api_version] || DEFAULT_PUPPET_SERVER_API
        api = puppet_catalog_api(api_version)
        raise ArgumentError, "Unsupported or invalid API version #{api_version}" unless api.is_a?(Hash)

        more_options = { headers: api[:headers], timeout: @timeout }
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
