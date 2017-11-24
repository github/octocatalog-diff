# This is a configuration file for octocatalog-diff

module OctocatalogDiff
  class Config
    def self.config
      {
        facts: OctocatalogDiff::Facts.new(
          backend: :yaml,
          fact_file_string: File.read(File.join(ENV['PUPPET_FACT_FILE_DIR'], 'valid-facts.yaml'))
        )
      }
    end
  end
end
