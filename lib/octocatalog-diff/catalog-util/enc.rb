# frozen_string_literal: true

require_relative 'enc/noop'
require_relative 'enc/pe'
require_relative 'enc/script'

require 'stringio'
require 'yaml'

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
      def content(logger = nil)
        execute(logger)
        @content ||= @enc_obj.content
      end

      # Retrieve error message
      # @return [String] Error message, or nil if there was no error
      def error_message(logger = nil)
        execute(logger)
        @error_message ||= @enc_obj.error_message
      end

      # Execute the 'execute' method of the object, but only once
      # @param [Logger] Logger (optional) - if not supplied any logger messages will be discarded
      def execute(logger = nil)
        return if @executed
        logger ||= @options[:logger]
        logger ||= Logger.new(StringIO.new)
        @enc_obj.execute(logger) if @enc_obj.respond_to?(:execute)
        @executed = true
        override_enc_parameters(logger)
      end

      private

      # Override of ENC parameters with parameters specified on the command line.
      # Modifies structures in @enc_obj.
      # @param logger [Logger] Logger object
      def override_enc_parameters(logger)
        return unless @options[:enc_override].is_a?(Array) && @options[:enc_override].any?
        content_structure = YAML.load(content)
        @options[:enc_override].each do |x|
          keys = x.key.is_a?(Regexp) ? content_structure.keys.select { |y| x.key.match(y) } : [x.key]
          keys.each do |key|
            merge_enc_param(content_structure, key, x.value)
            logger.debug "ENC override: #{key} #{x.value.nil? ? 'DELETED' : '= ' + x.value.inspect}"
          end
        end
        @content = content_structure.to_yaml
      end

      # Merging behavior for ENC overrides
      # @param pointer [Hash] Portion of the content structure to modify
      # @param key [String] String representing structure, delimited by '::'
      # @param value [?] Value to insert at structure point
      def merge_enc_param(pointer, key, value)
        if key =~ /::/
          first_key, the_rest = key.split(/::/, 2)
          if pointer[first_key].nil?
            pointer[first_key] = {}
          elsif !pointer[first_key].is_a?(Hash)
            raise ArgumentError, "Attempt to override #{pointer[first_key].class} with hash for #{key}"
          end
          merge_enc_param(pointer[first_key], the_rest, value)
        elsif value.nil?
          pointer.delete(key)
        else
          pointer[key] = value
        end
      end

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
    end
  end
end
