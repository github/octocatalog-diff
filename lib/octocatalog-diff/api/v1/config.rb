# frozen_string_literal: true

require_relative 'common'

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
        # @param :test [Boolean] Configuration file test mode only (test then exit)
        # @return [Hash] Parsed configuration file
        def self.config(options_in = {})
          # Initialize the logger - if not passed, set to a throwaway object.
          options, logger = OctocatalogDiff::API::V1::Common.logger_from_options(options_in)

          # Locate the configuration file
          paths = [options.fetch(:filename, DEFAULT_PATHS)].compact
          config_file = first_file(paths)
          if config_file.nil?
            message = "Unable to find configuration file in #{paths.join(':')}"
            raise Errno::ENOENT, message if options[:test]
            logger.debug message
            return {}
          end

          # Load the configuration file
          settings = load_config_file(config_file, logger)
          raise 'Configuration file failed to return a hash' unless settings.is_a?(Hash)

          # Debug the configuration file if requested.
          if options[:test]
            debug_config_file(settings, logger)
            logger.info 'Exiting now because --config-test was specified'
            exit 0
          end

          # Return the settings hash
          logger.debug "Loaded #{settings.keys.size} settings from #{config_file}"
          settings
        end

        # Private: Print debugging details for the configuration file.
        #
        # @param settings [Hash] Parsed settings from load_config_file
        # @param logger [Logger] Logger object
        def self.debug_config_file(settings, logger)
          settings.each do |key, val|
            logger.debug ":#{key} => (#{val.class}) #{val.inspect}"
          end
        end

        # Private: Load the configuration file from a given path. Returns the settings hash.
        #
        # @param filename [String] File name to load
        # @param logger [Logger] Logger object
        # @return [Hash] Settings
        def self.load_config_file(filename, logger)
          logger.debug "Loading octocatalog-diff configuration from #{filename}"
          require filename

          begin
            options = OctocatalogDiff::Config.config
          rescue => exc
            logger.fatal "#{exc.class} error with #{filename}: #{exc.message}\n#{exc.backtrace}"
            exit 1
          end

          unless options.is_a?(Hash)
            logger.fatal "Configuration must be Hash not #{options.class}!"
            exit 1
          end

          options
        rescue => exc
          logger.fatal "#{exc.class} error with #{filename}: #{exc.message}\n#{exc.backtrace}"
          raise 'Unable to load octocatalog-diff configuration file'
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
