# frozen_string_literal: true

require_relative 'errors'
require_relative 'util/httparty'

require 'uri'

# Redefine constants to match PuppetDB defaults.
# This code avoids warnings about redefining constants.
URI::HTTP.send(:remove_const, :DEFAULT_PORT) if URI::HTTP.const_defined?(:DEFAULT_PORT)
URI::HTTP.const_set(:DEFAULT_PORT, 8080)
URI::HTTPS.send(:remove_const, :DEFAULT_PORT) if URI::HTTPS.const_defined?(:DEFAULT_PORT)
URI::HTTPS.const_set(:DEFAULT_PORT, 8081)

module OctocatalogDiff
  # A standard way to connect to PuppetDB from the various scripts in this repository.
  class PuppetDB
    # Allow connections to be read (used in tests for now)
    attr_reader :connections

    # Constructor - will construct connection parameters from a variety
    # of sources, including arguments and environment variables. Supported
    # environment variables:
    #   PUPPETDB_URL
    #   PUPPETDB_HOST [+ PUPPETDB_PORT] [+ PUPPETDB_SSL]
    #
    # Order of precedence:
    #    1. :puppetdb_url argument (String or Array<String>)
    #    2. :puppetdb_host argument [+ :puppetdb_port] [+ :puppetdb_ssl]
    #    3. ENV['PUPPETDB_URL']
    #    4. ENV['PUPPETDB_HOST'] [+ ENV['PUPPETDB_PORT']], [+ ENV['PUPPETDB_SSL']]
    # When it finds one of these, it stops and does not process any others.
    #
    # When :puppetdb_url is an array, all given URLs are tried, in random order,
    # until a connection succeeds. If a connection succeeds, any errors from previously
    # failed connections are suppressed.
    #
    # Supported arguments:
    # @param :puppetdb_url [String or Array<String>] PuppetDB URL(s) to try in random order
    # @param :puppetdb_host [String] PuppetDB hostname, when constructing a URL
    # @param :puppetdb_port [Fixnum] Port number, defaults to 8080 (non-SSL) or 8081 (SSL)
    # @param :puppetdb_ssl [Boolean] defaults to true, because you should use SSL
    # @param :puppetdb_ssl_ca [String] Path to file containing CA certificate
    # @param :puppetdb_ssl_verify [Boolean] Override the CA verification setting guessed from parameters
    # @param :puppetdb_ssl_client_pem [String] PEM-encoded client key and certificate
    # @param :puppetdb_ssl_client_p12 [String] pkcs12-encoded client key and certificate
    # @param :puppetdb_ssl_client_password [String] Path to file containing password for SSL client key (any format)
    # @param :puppetdb_ssl_client_auth [Boolean] Override the client-auth that is guessed from parameters
    # @param :timeout [Fixnum] Connection timeout for PuppetDB (default=10)
    def initialize(options = {})
      @connections =
        if options.key?(:puppetdb_url)
          urls = options[:puppetdb_url].is_a?(Array) ? options[:puppetdb_url] : [options[:puppetdb_url]]
          urls.map { |url| parse_url(url) }
        elsif options.key?(:puppetdb_host)
          is_ssl = options.fetch(:puppetdb_ssl, true)
          default_port = is_ssl ? URI::HTTPS::DEFAULT_PORT : URI::HTTP::DEFAULT_PORT
          port = options.fetch(:puppetdb_port, default_port).to_i
          [{ ssl: is_ssl, host: options[:puppetdb_host], port: port }]
        elsif ENV['PUPPETDB_URL'] && !ENV['PUPPETDB_URL'].empty?
          [parse_url(ENV['PUPPETDB_URL'])]
        elsif ENV['PUPPETDB_HOST'] && !ENV['PUPPETDB_HOST'].empty?
          # Because environment variables are strings...
          # This will get the env var and see if it equals 'true'; the result
          # of this == comparison is the true/false boolean we need.
          is_ssl = ENV.fetch('PUPPETDB_SSL', 'true') == 'true'
          default_port = is_ssl ? URI::HTTPS::DEFAULT_PORT : URI::HTTP::DEFAULT_PORT
          port = ENV.fetch('PUPPETDB_PORT', default_port).to_i
          [{ ssl: is_ssl, host: ENV['PUPPETDB_HOST'], port: port }]
        else
          []
        end
      @timeout = options.fetch(:timeout, 10)
      @options = options
    end

    # Wrapper around the httparty call in the private _get method.
    # Returns the parsed result of getting the provided URL and returns
    # a friendlier error message if there are network connection problems
    # to PuppetDB.
    # @param path [String] Path portion of the URL
    # @return [Object] Parsed reply from PuppetDB as an object
    def get(path)
      _get(path)
    rescue Net::OpenTimeout, Errno::ECONNREFUSED => exc
      raise OctocatalogDiff::Errors::PuppetDBConnectionError, "#{exc.class} connecting to PuppetDB (need VPN on?): #{exc.message}"
    end

    private

    # HTTP(S) Query - will attempt to retrieve URL from each connection
    # @param path [String] Path portion of the URL
    # @return [String] Parsed response
    def _get(path)
      # You need at least one connection or else this can't do anything
      raise ArgumentError, 'No PuppetDB connections configured' if @connections.empty?

      # Keep track of the latest exception seen
      exc = nil

      # Try each connection in random order. This will return the first successful
      # response, and try the next connection if there's an error. Once it's out of
      # connections to try it will raise the last exception encountered.
      @connections.shuffle.each do |connection|
        complete_url = [
          connection[:ssl] ? 'https://' : 'http://',
          connection[:host],
          ':',
          connection[:port],
          path
        ].join('')

        begin
          more_options = { headers: { 'Accept' => 'application/json' }, timeout: @timeout }
          response = OctocatalogDiff::Util::HTTParty.get(complete_url, @options.merge(more_options), 'puppetdb')

          # Handle all non-200's from PuppetDB
          unless response[:code] == 200
            raise OctocatalogDiff::Errors::PuppetDBNodeNotFoundError, "404 - #{response[:error]}" if response[:code] == 404
            raise OctocatalogDiff::Errors::PuppetDBGenericError, "#{response[:code]} - #{response[:error]}"
          end

          # PuppetDB can return 'Not Found' as a string with a 200 response code
          raise NotFoundError, '404 - Not Found' if response[:body] == 'Not Found'

          # PuppetDB can also return an error message in a 200; we'll call this a 500
          if response.key?(:error)
            raise OctocatalogDiff::Errors::PuppetDBGenericError, "500 - #{response[:error]}"
          end

          # If we get here without raising an error, it will fall out of the begin/rescue
          # with 'result' non-nil, and 'result' will then get returned.
          raise "Unparseable response from puppetdb: '#{response.inspect}'" unless response[:parsed]
          result = response[:parsed]
        rescue => exc
          # Set response to nil so the loop repeats itself if there are retries left.
          # Also sets 'exc' to the most recent exception, in case all retries are
          # exhausted and this exception has to be raised.
          result = nil
        end

        # If the previous query didn't error, return result
        return result unless result.nil?
      end

      # At this point no query has succeeded, so raise the last error encountered.
      raise exc
    end

    # Parse a URL to determine hostname, port number, and whether or not SSL is used.
    # @param url [String] URL to parse
    # @return [Hash] { ssl: true/false, host: <String>, port: <Fixnum> }
    def parse_url(url)
      uri = URI(url)
      raise ArgumentError, "URL #{url} has invalid scheme" unless uri.scheme =~ /^https?$/
      { ssl: uri.scheme == 'https', host: uri.host, port: uri.port }
    rescue URI::InvalidURIError => exc
      raise exc.class, "Invalid URL: #{url} (#{exc.message})"
    end
  end
end
