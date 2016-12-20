# frozen_string_literal: true

module OctocatalogDiff
  # Determine the version of octocatalog-diff
  class Version
    version_file = File.expand_path('../../.version', File.dirname(__FILE__))
    VERSION = File.read(version_file).strip.freeze
  end
end
