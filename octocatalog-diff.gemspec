require 'json'

DEFAULT_PUPPET_VERSION = '5.5.22'.freeze

Gem::Specification.new do |s|
  s.required_ruby_version = '>= 2.5.0'

  s.name        = 'octocatalog-diff'
  s.version     = ENV['OCTOCATALOG_DIFF_VERSION'] || File.read(File.join(File.dirname(__FILE__), '.version')).strip
  s.license     = 'MIT'
  s.authors     = ['GitHub, Inc.', 'Kevin Paulisse']
  s.email       = 'opensource+octocatalog-diff@github.com'
  s.files       = Dir.glob('doc/**/*.md') \
                + Dir.glob('lib/**/*') \
                + Dir.glob('scripts/**/*') \
                + %w(LICENSE README.md .version bin/octocatalog-diff)
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
  s.add_runtime_dependency 'parallel', '>= 1.12.0'
  s.add_runtime_dependency 'rugged', '>= 0.25.0b2'

  s.add_development_dependency 'rspec', '~> 3.4.0'
  s.add_development_dependency 'rake', '13.0.0'
  s.add_development_dependency 'parallel_tests', '2.7.1'
  s.add_development_dependency 'rspec-retry', '0.5.0'

  s.add_development_dependency 'rubocop', '= 0.49.0'

  s.add_development_dependency 'simplecov', '~> 0.14.1'
  s.add_development_dependency 'simplecov-erb', '~> 0.1.1'

  puppet_version = ENV['PUPPET_VERSION'] || DEFAULT_PUPPET_VERSION
  s.add_development_dependency 'puppet', "~> #{puppet_version}"

  puppet_v = Gem::Version.new(puppet_version)
  version_config = JSON.parse(File.read(File.join(File.dirname(__FILE__), 'config', 'puppet-versions.json')))
  version_config.each do |data|
    next unless puppet_v >= Gem::Version.new(data['minimum_version'])
    next unless puppet_v <= Gem::Version.new(data['maximum_version'])
    data['additional_gems'].each do |additional_gem|
      s.add_development_dependency additional_gem['name'], additional_gem['version']
    end
  end
end
