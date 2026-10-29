lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "octocatalog-diff/version"

Gem::Specification.new do |spec|
  spec.name        = 'octocatalog-diff'
  spec.version     = OctocatalogDiff::VERSION
  spec.license     = 'MIT'
  spec.authors     = ['SysEleven GmbH', 'GitHub, Inc.', 'Kevin Paulisse']
  spec.email       = ['opensource@syseleven.de']
  spec.homepage    = 'https://github.com/syseleven/octocatalog-diff'
  spec.summary     = 'Compile OpenVox/Puppet catalogs from 2 branches, versions, etc., and compare them.'
  spec.description = <<~DESC
    Octocatalog-Diff assists with Puppet/OpenVox development and testing by enabling the
    user to compile 2 catalogs and compare them. It is possible to compare different
    branches, different versions, and different fact valuespec. This is intended to be run
    from a local development environment or in CI. This is the SysEleven fork, updated
    for OpenVox 8 and Ruby >= 3.2.
  DESC

  spec.files = Dir.glob('doc/**/*.md') \
          + Dir.glob('lib/**/*') \
          + Dir.glob('scripts/**/*') \
          + %w[LICENSE README.md bin/octocatalog-diff]
  
  spec.require_paths = ['lib']
  spec.executables = ['octocatalog-diff']

  spec.required_ruby_version = ['>= 3.2']

  spec.metadata = {
    'github_repo' => 'ssh://github.com/syseleven/octocatalog-diff',
    'homepage_uri' => 'https://github.com/syseleven/octocatalog-diff',
    'source_code_uri' => 'https://github.com/syseleven/octocatalog-diff',
    'bug_tracker_uri' => 'https://github.com/syseleven/octocatalog-diff/issues',
    'changelog_uri' => 'https://github.com/syseleven/octocatalog-diff/blob/master/doc/CHANGELOG.md',
  }

  spec.add_runtime_dependency 'diffy',    '>= 3.4.4', '< 4'
  spec.add_runtime_dependency 'hashdiff', '>= 1.2.1', '< 2'
  spec.add_runtime_dependency 'httparty', '>= 0.24.3', '< 1'
  spec.add_runtime_dependency 'openvox',  '>= 8.19', '< 9'
  spec.add_runtime_dependency 'parallel', '>= 2.3', '< 3'
  spec.add_runtime_dependency 'rugged',   '>= 1.9.6', '< 2'
end
