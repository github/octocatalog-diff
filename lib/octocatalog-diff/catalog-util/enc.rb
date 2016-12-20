# frozen_string_literal: true

require_relative 'enc/noop'
require_relative 'enc/pe'
require_relative 'enc/script'

require 'stringio'

module OctocatalogDiff
  module CatalogUtil
    # Support a generic ENC. It must use one of the supported backends found in the
    # 'enc' subdirectory.
    class ENC
      attr_reader :builder

      # Constructor
      # @param :backend [Symbol] If set, this will force a backend
      # @param :enc [String] Path to ENC script (node_terminus = exec)
      # @param # FIXME: Add support for PE's ENC endpoint API
      def initialize(options = {})
        @options = options

        # Determine appropriate backend based on options supplied
        @enc_obj = backend

        # Initialize instance variables for content and error message.
        @builder = @enc_obj.class.to_s

        # Set the executed flag to false, so that it can be executed when something is retrieved.
        @executed = false
      end

      # Retrieve content
      # @return [String] ENC content, or nil if there was an error
      def content
        execute
        @content ||= @enc_obj.content
      end

      # Retrieve error message
      # @return [String] Error message, or nil if there was no error
      def error_message
        execute
        @error_message ||= @enc_obj.error_message
      end

      private

      # Backend - given options, choose an appropriate backend and construct the corresponding object.
      # @return [?] Backend object
      def backend
        # Hard-coded backend
        if @options[:backend]
          return OctocatalogDiff::CatalogUtil::ENC::Noop.new(@options) if @options[:backend] == :noop
          return OctocatalogDiff::CatalogUtil::ENC::PE.new(@options) if @options[:backend] == :pe
          return OctocatalogDiff::CatalogUtil::ENC::Script.new(@options) if @options[:backend] == :script
          raise ArgumentError, "Unknown backend :#{@options[:backend]}"
        end

        # Determine backend based on arguments
        return OctocatalogDiff::CatalogUtil::ENC::PE.new(@options) if @options[:pe_enc_url]
        return OctocatalogDiff::CatalogUtil::ENC::Script.new(@options) if @options[:enc]

        # At this point we do not know what backend to use for the ENC
        raise ArgumentError, 'Unable to determine ENC backend to use'
      end

      # Execute the 'execute' method of the object, but only once
      # @param [Logger] Logger (optional) - if not supplied any logger messages will be discarded
      def execute(logger = nil)
        return if @executed
        logger ||= @options[:logger]
        logger ||= Logger.new(StringIO.new)
        @enc_obj.execute(logger) if @enc_obj.respond_to?(:execute)
        @executed = true
      end
    end
  end
end
