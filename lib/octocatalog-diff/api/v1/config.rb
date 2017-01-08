# frozen_string_literal: true

require_relative 'common'
require_relative '../../errors'

module OctocatalogDiff
  module API
    module V1
      # This class interacts with the configuration file typically named `.octocatalog-diff.cfg.rb`.
      class Config
        # Default directory paths: These are the documented default locations that will be checked
        # for the configuration file.
        DEFAULT_PATHS = [
          ENV['OCTOCATALOG_DIFF_CONFIG_FILE'],
          File.join(Dir.pwd, '.octocatalog-diff.cfg.rb'),
          File.join(ENV['HOME'], '.octocatalog-diff.cfg.rb'),
          '/opt/puppetlabs/octocatalog-diff/octocatalog-diff.cfg.rb',
          '/usr/local/etc/octocatalog-diff.cfg.rb',
          '/etc/octocatalog-diff.cfg.rb'
        ].compact.freeze

        # Public: Find the configuration file in the specified path or one of the default paths
        # as appropriate. Parses the configuration file and returns the hash object with its settings.
        # Returns empty hash if the configuration file is not found anywhere.
        #
        # @param :filename [String] Specified file name (default = search the default paths)
        # @param :logger [Logger] Logger object
        # @param :test [Boolean] Configuration file test mode (log some extra debugging, raises errors)
        # @return [Hash] Parsed configuration file
        def self.config(options_in = {})
          # Initialize the logger - if not passed, set to a throwaway object.
          options, logger = OctocatalogDiff::API::V1::Common.logger_from_options(options_in)

          # Locate the configuration file
          paths = [options.fetch(:filename, DEFAULT_PATHS)].compact
          config_file = first_file(paths)

          # Can't find the configuration file?
          if config_file.nil?
            message = "Unable to find configuration file in #{paths.join(':')}"
            raise OctocatalogDiff::Errors::ConfigurationFileNotFoundError, message if options[:test]
            logger.debug message
            return {}
          end

          # Load/parse the configuration file - this returns a hash
          settings = load_config_file(config_file, logger)

          # Debug the configuration file if requested.
          debug_config_file(settings, logger) if options[:test]

          # Return the settings hash
          logger.debug "Loaded #{settings.keys.size} settings from #{config_file}"
          settings
        end

        # Private: Print debugging details for the configuration file.
        #
        # @param settings [Hash] Parsed settings from load_config_file
        # @param logger [Logger] Logger object
        def self.debug_config_file(settings, logger)
          unless settings.is_a?(Hash)
            raise ArgumentError, "Settings must be hash not #{settings.class}"
          end

          settings.each { |key, val| logger.debug ":#{key} => (#{val.class}) #{val.inspect}" }
        end

        # Private: Load the configuration file from a given path. Returns the settings hash.
        #
        # @param filename [String] File name to load
        # @param logger [Logger] Logger object
        # @return [Hash] Settings
        def self.load_config_file(filename, logger)
          # This should never happen unless somebody calls this method directly outside of
          # the published `.config` method. Check for problems anyway.
          raise Errno::ENOENT, "File #{filename} doesn't exist" unless File.file?(filename)

          # Attempt to require in the file. Problems here will fall through to the rescued
          # exception below.
          logger.debug "Loading octocatalog-diff configuration from #{filename}"
          load filename

          # The required file should contain `OctocatalogDiff::Config` with `.config` method.
          # If this is undefined, raise an exception.
          begin
            loaded_class = Kernel.const_get(:OctocatalogDiff).const_get(:Config)
          rescue NameError
            message = 'Configuration must define OctocatalogDiff::Config!'
            raise OctocatalogDiff::Errors::ConfigurationFileContentError, message
          end

          unless loaded_class.respond_to?(:config)
            message = 'Configuration must define OctocatalogDiff::Config.config!'
            raise OctocatalogDiff::Errors::ConfigurationFileContentError, message
          end

          # The configuration file looks like it defines the correct method, so read it.
          # Make sure it's a hash.
          options = loaded_class.config
          unless options.is_a?(Hash)
            message = "Configuration must be Hash not #{options.class}!"
            raise OctocatalogDiff::Errors::ConfigurationFileContentError, message
          end

          options
        rescue Exception => exc # rubocop:disable Lint/RescueException
          logger.fatal "#{exc.class} error with #{filename}: #{exc.message}\n#{exc.backtrace}"
          raise exc
        end

        # Private: Find the first element of the given array that is a file and return it.
        # Return nil if none of the elements in the array are files.
        #
        # @param search_paths [Array<String>] Paths to check
        def self.first_file(search_paths)
          search_paths.flatten.compact.each do |path|
            return path if File.file?(path)
          end
          nil
        end
      end
    end
  end
end
