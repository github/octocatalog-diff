require_relative 'lib/octocatalog-diff/version'

DEFAULT_PUPPET_VERSION = '4.10.0'.freeze

Gem::Specification.new do |s|
  s.required_ruby_version = '>= 2.0.0'

  s.name        = 'octocatalog-diff'
  s.version     = ENV['OCTOCATALOG_DIFF_VERSION'] || OctocatalogDiff::Version::VERSION
  s.license     = 'MIT'
  s.authors     = ['GitHub, Inc.', 'Kevin Paulisse']
  s.email       = 'opensource+octocatalog-diff@github.com'
  # rubocop:disable LineLength
  s.files       = Dir.glob('doc/**/*.md') + Dir.glob('lib/**/*') + Dir.glob('scripts/**/*') + %w(LICENSE README.md .version bin/octocatalog-diff)
  # rubocop:enable LineLength
  s.executables = 'octocatalog-diff'
  s.homepage    = 'https://github.com/github/octocatalog-diff'
  s.summary     = 'Compile Puppet catalogs from 2 branches, versions, etc., and compare them.'
  s.description = <<-EOF
Octocatalog-Diff assists with Puppet development and testing by enabling the user to
compile 2 Puppet catalogs and compare them. It is possible to compare different
branches, different versions, and different fact values. This is intended to be run
from a local development environment or in CI.
EOF

  s.add_runtime_dependency 'diffy', '>= 3.1.0'
  s.add_runtime_dependency 'httparty', '>= 0.11.0'
  s.add_runtime_dependency 'hashdiff', '>= 0.3.0'
  s.add_runtime_dependency 'rugged', '>= 0.25.0b2'

  s.add_development_dependency 'rspec', '~> 3.4.0'
  s.add_development_dependency 'rake', '11.2.2'
  s.add_development_dependency 'parallel_tests', '2.7.1'
  s.add_development_dependency 'rspec-retry', '0.5.0'

  s.add_development_dependency 'rubocop', '= 0.48.1'

  s.add_development_dependency 'puppetdb-terminus', '3.2.4'

  s.add_development_dependency 'simplecov', '>= 0.14.1'
  s.add_development_dependency 'simplecov-json'

  if ENV['PUPPET_VERSION']
    s.add_development_dependency 'puppet', "~> #{ENV['PUPPET_VERSION']}"
    if ENV['PUPPET_VERSION'] =~ /^3/
      s.add_development_dependency 'safe_yaml', '~> 1.0.4'
    end
  else
    s.add_development_dependency 'puppet', "~> #{DEFAULT_PUPPET_VERSION}"
  end
end
