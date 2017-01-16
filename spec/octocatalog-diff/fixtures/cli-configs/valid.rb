# This is a configuration file for octocatalog-diff

module OctocatalogDiff
  class Config
    def self.config
      {
        header: :default,
        hiera_config: 'config/hiera.yaml',
        hiera_path: 'hieradata'
      }
    end
  end
end
