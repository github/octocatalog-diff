# frozen_string_literal: true

module OctocatalogDiff
  # Contains error classes raised by this gem
  class Errors
    # Error classes for handled configuration file errors
    class ConfigurationFileNotFoundError < RuntimeError; end
    class ConfigurationFileContentError < RuntimeError; end

    # Error classes for building catalogs
    class BootstrapError < RuntimeError; end
    class CatalogError < RuntimeError; end
  end
end
