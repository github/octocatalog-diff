Gem::Specification.new do |s|
  s.name        = 'octocatalog-diff'
  s.version     = ENV['OCTOCATALOG_DIFF_VERSION'] || File.read(File.join(__dir__, '.version')).strip
  s.license     = 'MIT'
  s.authors     = ['SysEleven GmbH', 'GitHub, Inc.', 'Kevin Paulisse']
  s.email       = ['opensource@syseleven.de']
  s.homepage    = 'https://github.com/syseleven/octocatalog-diff'
  s.summary     = 'Compile OpenVox/Puppet catalogs from 2 branches, versions, etc., and compare them.'
  s.description = <<~DESC
    Octocatalog-Diff assists with Puppet/OpenVox development and testing by enabling the
    user to compile 2 catalogs and compare them. It is possible to compare different
    branches, different versions, and different fact values. This is intended to be run
    from a local development environment or in CI. This is the SysEleven fork, updated
    for OpenVox 8 and Ruby >= 3.2.
  DESC

  s.files = Dir.glob('doc/**/*.md') \
          + Dir.glob('lib/**/*') \
          + Dir.glob('scripts/**/*') \
          + %w[LICENSE README.md .version bin/octocatalog-diff]
  s.executables = ['octocatalog-diff']

  s.required_ruby_version = ['>= 3.2', '< 4']

  s.metadata = {
    'github_repo' => 'ssh://github.com/syseleven/octocatalog-diff',
    'homepage_uri' => 'https://github.com/syseleven/octocatalog-diff',
    'source_code_uri' => 'https://github.com/syseleven/octocatalog-diff',
    'bug_tracker_uri' => 'https://github.com/syseleven/octocatalog-diff/issues',
    'changelog_uri' => 'https://github.com/syseleven/octocatalog-diff/blob/master/doc/CHANGELOG.md',
  }

  s.add_dependency 'diffy',    '>= 3.4', '< 4'
  s.add_dependency 'hashdiff', '>= 1.0', '< 2'
  s.add_dependency 'httparty', '~> 0.21'
  s.add_dependency 'openvox',  '>= 8.19', '< 9'
  s.add_dependency 'parallel', '>= 1.24', '< 2'
  s.add_dependency 'rugged',   '>= 1.6', '< 2'
end
