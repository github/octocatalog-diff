# frozen_string_literal: true

require 'httparty'
require 'json'
require_relative '../external/pson/pure'

module OctocatalogDiff
  module Util
    # This is a wrapper around some common actions that octocatalog-diff does when preparing to talk
    # to a web server using 'httparty'.
    class HTTParty
      # Wrap the 'get' method in httparty with SSL options
      # @param url [String] URL to retrieve
      # @param options [Hash] Options
      # @param ssl_prefix [String] Strip "#{prefix}_" from the start of SSL options to generalize them
      # @return [Hash] HTTParty response and codes
      def self.get(url, options = {}, ssl_prefix = nil)
        httparty_response_parse(::HTTParty.get(url, options.merge(wrap_ssl_options(options, ssl_prefix))))
      end

      # Wrap the 'post' method in httparty with SSL options
      # @param url [String] URL to retrieve
      # @param options [Hash] Options
      # @param post_body [String] Test to POST
      # @param ssl_prefix [String] Strip "#{prefix}_" from the start of SSL options to generalize them
      # @return [Hash] HTTParty response and codes
      def self.post(url, options, post_body, ssl_prefix)
        opts = options.merge(wrap_ssl_options(options, ssl_prefix))
        httparty_response_parse(::HTTParty.post(url, opts.merge(body: post_body)))
      end

      # Common parser for HTTParty response
      # @param response [HTTParty response object] HTTParty response object
      # @return [Hash] HTTParty parsed response and codes
      def self.httparty_response_parse(response)
        # Handle HTTP errors
        unless response.code == 200
          begin
            b = JSON.parse(response.body)
            errormessage = b['error'] if b.is_a?(Hash) && b.key?('error')
          rescue JSON::ParserError
            errormessage = response.body
          ensure
            errormessage ||= response.body
          end
          return { code: response.code, body: response.body, error: errormessage }
        end

        # Handle success
        if response.headers.key?('content-type')
          if response.headers['content-type'] =~ %r{/json}
            begin
              return { code: 200, body: response.body, parsed: JSON.parse(response.body) }
            rescue JSON::ParserError => exc
              return { code: 500, body: response.body, error: "JSON parse error: #{exc.message}" }
            end
          end
          if response.headers['content-type'] =~ %r{/pson}
            begin
              return { code: 200, body: response.body, parsed: PSON.parse(response.body) }
            rescue PSON::ParserError => exc
              return { code: 500, body: response.body, error: "PSON parse error: #{exc.message}" }
            end
          end
          return { code: 500, body: response.body, error: "Don't know how to parse: #{response.headers['content-type']}" }
        end

        # Return raw output
        { code: response.code, body: response.body }
      end

      # Wrap context-specific options into generally named options for the other methods in this class
      # @param options [Hash] Hash of all options
      # @param prefix [String] Prefix to strip from SSL options
      # @return [Hash] SSL options generally named
      def self.wrap_ssl_options(options, prefix)
        return {} unless prefix
        result = {}
        options.keys.each do |key|
          next if key.to_s !~ /^#{prefix}_(ssl_.*)/
          result[Regexp.last_match[1].to_sym] = options[key]
        end
        ssl_options(result)
      end

      # SSL options to add to the httparty options hash
      # @param :ssl_ca [String] Optional: File with SSL CA certificate
      # @param :ssl_client_key [String] Full text of SSL client private key
      # @param :ssl_client_cert [String] Full text of SSL client public cert
      # @param :ssl_client_pem [String] Full text of SSL client private key + client public cert
      # @param :ssl_client_p12 [String] Full text of pkcs12-encoded keypair
      # @param :ssl_client_password [String] Password to unlock private key
      # @return [Hash] Hash of SSL options to pass to httparty
      def self.ssl_options(options)
        # Initialize the result
        result = {}

        # Verification of server against a known CA cert
        if ssl_verify?(options)
          result[:verify] = true
          raise ArgumentError, ':ssl_ca must be passed' unless options[:ssl_ca].is_a?(String)
          raise Errno::ENOENT, "'#{options[:ssl_ca]}' not a file" unless File.file?(options[:ssl_ca])
          result[:ssl_ca_file] = options[:ssl_ca]
        else
          result[:verify] = false
        end

        # SSL client certificate auth. This translates our options into httparty options.
        if client_auth?(options)
          if options[:ssl_client_key].is_a?(String) && options[:ssl_client_cert].is_a?(String)
            result[:pem] = options[:ssl_client_key] + options[:ssl_client_cert]
          elsif options[:ssl_client_pem].is_a?(String)
            result[:pem] = options[:ssl_client_pem]
          elsif options[:ssl_client_p12].is_a?(String)
            result[:p12] = options[:ssl_client_p12]
            raise ArgumentError, 'pkcs12 requires a password' unless options[:ssl_client_password]
            result[:p12_password] = options[:ssl_client_password]
          else
            raise ArgumentError, 'SSL client auth enabled but no client keypair specified'
          end

          # Make sure there's not a password required, or that if the password is given, it is correct.
          # This will raise OpenSSL::PKey::RSAError if the key needs a password.
          if result[:pem] && options[:ssl_client_password]
            result[:pem_password] = options[:ssl_client_password]
            _trash = OpenSSL::PKey::RSA.new(result[:pem], result[:pem_password])
          elsif result[:pem]
            # Ruby 2.4 requires a minimum password length of 4. If no password is needed for
            # the certificate, the specified password here is effectively ignored.
            # We do not want to wait on STDIN, so a password-protected certificate without a
            # password will cause this to raise an error. There are two checks here, to exclude
            # an edge case where somebody did actually put '1234' as their password.
            _trash = OpenSSL::PKey::RSA.new(result[:pem], '1234')
            _trash = OpenSSL::PKey::RSA.new(result[:pem], '5678')
          end
        end

        # Return result
        result
      end

      # Determine, based on options, whether SSL client certificates need to be used.
      # The order of precedence is:
      # - If options[:ssl_client_auth] is not nil, return it
      # - If (key and cert) or PEM or PKCS12 are set, return true
      # - Else return false
      # @return [Boolean] see description
      def self.client_auth?(options)
        return options[:ssl_client_auth] unless options[:ssl_client_auth].nil?
        return true if options[:ssl_client_cert].is_a?(String) && options[:ssl_client_key].is_a?(String)
        return true if options[:ssl_client_pem].is_a?(String)
        return true if options[:ssl_client_p12].is_a?(String)
        false
      end

      # Determine, based on options, whether SSL certificates should be verified.
      # The order of precedence is:
      # - If options[:ssl_verify] is not nil, return it
      # - If options[:ssl_ca] is defined, return true
      # - Else return false
      # @return [Boolean] see description
      def self.ssl_verify?(options)
        return options[:ssl_verify] unless options[:ssl_verify].nil?
        options[:ssl_ca].is_a?(String)
      end
    end
  end
end
