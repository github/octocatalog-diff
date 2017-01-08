# frozen_string_literal: true

module OctocatalogDiff
  # Contains error classes raised by this gem
  class Errors
    # Error class for handled configuration file errors
    class ConfigurationFileNotFoundError < RuntimeError; end
    class ConfigurationFileContentError < RuntimeError; end
  end
end
