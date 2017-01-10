# frozen_string_literal: true

require 'json'
require 'uri'
require 'yaml'

require_relative '../../../errors'

module OctocatalogDiff
  module CatalogUtil
    class ENC
      class PE
        # Support the Puppet Enterprise classification API.
        # Documentation: https://docs.puppet.com/pe/latest/nc_index.html
        # This is version 1 of the API
        class V1
          # Constructor
          # @param options [Hash] All input options
          def initialize(options)
            @options = options
          end

          # Return the URL to the API
          # @return [String] API URL
          def url
            "#{@options[:pe_enc_url]}/v1/classified/nodes/#{@options[:node]}"
          end

          # Headers
          # @return [Hash] Headers for request
          def headers
            result = {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json'
            }
            result['X-Authentication'] = @options[:pe_enc_token] if @options[:pe_enc_token]
            result
          end

          # POST body
          # @return [String] POST body data
          def body
            raise ":facts required (got #{@options[:facts].class})" unless @options[:facts].is_a?(OctocatalogDiff::Facts)
            { 'fact' => @options[:facts].facts }.to_json
          end

          # Parse response from ENC and return the final ENC data
          # @param parsed [Parsed response] Parsed response from ENC
          # @param logger [Logger] Logger.object
          # @return [String] ENC data as text
          def result(parsed, logger)
            %w(classes parameters).each do |required_key|
              next if parsed[required_key]
              logger.debug parsed.keys.inspect
              raise OctocatalogDiff::Errors::PEClassificationError, "Response missing: #{required_key}"
            end

            obj = { 'classes' => parsed['classes'], 'parameters' => parsed['parameters'] }
            obj.to_yaml
          end
        end
      end
    end
  end
end
