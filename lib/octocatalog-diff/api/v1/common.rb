# frozen_string_literal: true

module OctocatalogDiff
  module API
    module V1
      # Common functions for API v1
      class Common
        def self.logger_from_options(options)
          # If logger is not provided, create an object that can have messages written to it.
          # There won't be a way to access these messages, so if you want to log messages, then
          # provide that logger!
          logger = options[:logger] || Logger.new(StringIO.new)

          # We can't keep :logger in the options due to marshal/unmarshal as part of parallelization.
          pass_opts = options.dup
          pass_opts.delete(:logger)

          # Return cleaned options and logger
          [pass_opts, logger]
        end
      end
    end
  end
end
