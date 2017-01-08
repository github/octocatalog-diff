# frozen_string_literal: true

require_relative 'pe/v1'
require_relative '../../util/httparty'
require_relative '../../errors'
require_relative '../facts'

module OctocatalogDiff
  module CatalogUtil
    class ENC
      # Support the Puppet Enterprise classification API.
      # Documentation: https://docs.puppet.com/pe/latest/nc_index.html
      class PE
        # Allow the main ENC object to retrieve these values
        attr_reader :content, :error_message

        # Constructor
        # @param options [Hash] Options - must contain the Puppet Enterprise URL and the node
        def initialize(options)
          # Make sure the node is in the options
          raise ArgumentError, 'OctocatalogDiff::CatalogUtil::ENC::PE#new requires :node' unless options.key?(:node)
          @node = options[:node]

          # Retrieve the base URL for the Puppet Enterprise ENC service
          raise ArgumentError, 'OctocatalogDiff::CatalogUtil::ENC::PE#new requires :pe_enc_url' unless options.key?(:pe_enc_url)

          # Save options
          @options = options

          # Get the object corresponding to the version of the API in use.
          # (Right now this is hard-coded at V1 because that is the only version there is. In the future
          # if there are different versions, this will need to be parameterized.)
          @api = OctocatalogDiff::CatalogUtil::ENC::PE::V1.new(@options)

          # Initialize the content and error message
          @content = nil
          @error_message = 'The execute method was never run'
        end

        # Executor
        # @param logger [Logger] Logger object
        def execute(logger)
          logger.debug "Beginning OctocatalogDiff::CatalogUtil::ENC::PE#execute for #{@node}"

          @options[:facts] ||= facts(logger)
          return unless @options[:facts]

          more_options = { headers: @api.headers, timeout: @options[:timeout] || 10 }
          post_hash = @api.body
          url = @api.url
          response = OctocatalogDiff::Util::HTTParty.post(url, @options.merge(more_options), post_hash, 'pe_enc')

          unless response[:code] == 200
            logger.debug "PE ENC failed: #{response.inspect}"
            logger.error "PE ENC failed: Response from #{url} was #{response[:code]}"
            @error_message = "Response from #{url} was #{response[:code]}"
            return
          end

          logger.debug "Response from #{url} was #{response[:code]}"
          unless response[:parsed].is_a?(Hash)
            logger.error "PE ENC failed: Response from #{url} was not a hash! #{response[:parsed].inspect}"
            @error_message = "PE ENC failed: Response from #{url} was not a hash! #{response[:parsed].class}"
            return
          end

          begin
            @content = @api.result(response[:parsed], logger)
            @error_message = nil
          rescue OctocatalogDiff::Errors::PEClassificationError => exc
            @error_message = exc.message
            logger.error "PE ENC failed: #{exc.message}"
            return
          end

          logger.debug "Completed OctocatalogDiff::CatalogUtil::ENC::PE#execute for #{@node}"
        end

        # Facts
        # @param logger [Logger] Logger object
        # @return [OctocatalogDiff::Facts] Facts object
        def facts(logger)
          facts_obj = OctocatalogDiff::CatalogUtil::Facts.new(@options, logger)
          logger.debug "Start retrieving facts for #{@node} from #{self.class}"
          begin
            result = facts_obj.facts
            logger.debug "Success retrieving facts for #{@node} from #{self.class}"
          rescue OctocatalogDiff::Errors::FactRetrievalError, OctocatalogDiff::Errors::FactSourceError => exc
            @content = nil
            @error_message = "Fact retrieval failed: #{exc.class} - #{exc.message}"
            logger.error @error_message
            result = nil
          end
          result
        end
      end
    end
  end
end
