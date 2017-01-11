# frozen_string_literal: true

# This is test coverage on the `bin/octocatalog-diff` script itself.

require_relative '../tests/spec_helper'
require 'open3'
require 'shellwords'

describe 'bin/octocatalog-diff' do
  let(:script) { File.expand_path('../../../bin/octocatalog-diff', File.dirname(__FILE__)) }

  context 'config test' do
    context 'config file found' do
      it 'should display configuration settings and then exit 0' do
        env = { 'OCTOCATALOG_DIFF_CONFIG_FILE' => OctocatalogDiff::Spec.fixture_path('cli-configs/valid.rb') }
        argv = ['--config-test']

        cmdline = [script, argv].flatten.map { |x| Shellwords.escape(x) }.join(' ')
        stdout, stderr, status = Open3.capture3(env, cmdline)

        expect(status.exitstatus).to eq(0)
        expect(stdout).to eq('')
        expect(stderr).to match(%r{Loading octocatalog-diff configuration from .+/cli-configs/valid.rb})
        expect(stderr).to match(/DEBUG -- : :header => \(Symbol\) :default/)
        expect(stderr).to match(/DEBUG -- : Loaded 3 settings from/)
        expect(stderr).to match(/INFO -- : Exiting now because --config-test was specified/)
      end
    end

    context 'invalid config file' do
      it 'should raise error and exit 1' do
        env = { 'OCTOCATALOG_DIFF_CONFIG_FILE' => OctocatalogDiff::Spec.fixture_path('cli-configs/invalid.rb') }
        argv = ['--config-test']

        cmdline = [script, argv].flatten.map { |x| Shellwords.escape(x) }.join(' ')
        stdout, stderr, status = Open3.capture3(env, cmdline)

        expect(status.exitstatus).to eq(1)
        expect(stdout).to eq('')
        expect(stderr).to match(%r{Loading octocatalog-diff configuration from .+/cli-configs/invalid.rb})
        expect(stderr).to match(/FATAL -- : RuntimeError error with.+Fizz Buzz/)
      end
    end
  end

  context 'normal' do
    context 'with valid catalogs that differ' do
      it 'should display output and exit 2' do
        env = { 'OCTOCATALOG_DIFF_CONFIG_FILE' => OctocatalogDiff::Spec.fixture_path('cli-configs/valid.rb') }
        argv = [
          '--bootstrapped-to-dir', OctocatalogDiff::Spec.fixture_path('repos/default'),
          '--from-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog.json'),
          '--puppet-binary', OctocatalogDiff::Spec::PUPPET_BINARY,
          '--fact-file', OctocatalogDiff::Spec.fixture_path('facts/facts.json'),
          '-n', 'rspec-node.github.net',
          '--no-color'
        ]

        cmdline = [script, argv].flatten.map { |x| Shellwords.escape(x) }.join(' ')
        stdout, stderr, status = Open3.capture3(env, cmdline)

        expect(status.exitstatus).to eq(2), [stdout, stderr].join("\n")

        out_lines = stdout.split(/\n/)
        expect(out_lines).to include('diff origin/master/rspec-node.github.net current/rspec-node.github.net')
        expect(out_lines).to include('+ File[/root/.ssh]')
        expect(out_lines).to include('+ System::User[bob]')

        expect(stderr).to match(%r{Loading octocatalog-diff configuration from .+/cli-configs/valid.rb})
        expect(stderr).not_to match(/DEBUG -- : :header => \(Symbol\) :default/)
        expect(stderr).to match(/DEBUG -- : Loaded 3 settings from/)
        expect(stderr).not_to match(/INFO -- : Exiting now because --config-test was specified/)
        expect(stderr).to match(/INFO -- : Catalogs compiled for rspec-node.github.net/)
        expect(stderr).to match(/INFO -- : Diffs computed for rspec-node.github.net/)
        expect(stderr).to match(/INFO -- : Note: you can use --display-detail-add/)
      end
    end

    context 'with no changes' do
      it 'should display output and exit 0' do
        env = { 'OCTOCATALOG_DIFF_CONFIG_FILE' => OctocatalogDiff::Spec.fixture_path('cli-configs/valid.rb') }
        argv = [
          '--bootstrapped-to-dir', OctocatalogDiff::Spec.fixture_path('repos/tiny-repo'),
          '--from-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog.json'),
          '--puppet-binary', OctocatalogDiff::Spec::PUPPET_BINARY,
          '--fact-file', OctocatalogDiff::Spec.fixture_path('facts/facts.json'),
          '-n', 'rspec-node.github.net',
          '--no-color',
          '--no-hiera-config'
        ]

        cmdline = [script, argv].flatten.map { |x| Shellwords.escape(x) }.join(' ')
        stdout, stderr, status = Open3.capture3(env, cmdline)

        expect(status.exitstatus).to eq(0), [stdout, stderr].join("\n")

        expect(stdout).to eq('')

        expect(stderr).to match(%r{Loading octocatalog-diff configuration from .+/cli-configs/valid.rb})
        expect(stderr).not_to match(/DEBUG -- : :header => \(Symbol\) :default/)
        expect(stderr).to match(/DEBUG -- : Loaded 3 settings from/)
        expect(stderr).not_to match(/INFO -- : Exiting now because --config-test was specified/)
        expect(stderr).to match(/INFO -- : Catalogs compiled for rspec-node.github.net/)
        expect(stderr).to match(/INFO -- : Diffs computed for rspec-node.github.net/)
        expect(stderr).to match(/INFO -- : No differences/)
      end
    end

    context 'when encountering an error in catalog compilation' do
      it 'should display error and exit 1' do
        env = { 'OCTOCATALOG_DIFF_CONFIG_FILE' => OctocatalogDiff::Spec.fixture_path('cli-configs/valid.rb') }
        argv = [
          '--bootstrapped-to-dir', OctocatalogDiff::Spec.fixture_path('repos/failing-catalog'),
          '--from-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog.json'),
          '--puppet-binary', OctocatalogDiff::Spec::PUPPET_BINARY,
          '--fact-file', OctocatalogDiff::Spec.fixture_path('facts/facts.json'),
          '-n', 'rspec-node.github.net',
          '--no-color',
          '--no-hiera-config'
        ]

        cmdline = [script, argv].flatten.map { |x| Shellwords.escape(x) }.join(' ')
        stdout, stderr, status = Open3.capture3(env, cmdline)

        expect(status.exitstatus).to eq(1), [stdout, stderr].join("\n")

        expect(stdout).to eq('')

        expect(stderr).to match(%r{Loading octocatalog-diff configuration from .+/cli-configs/valid.rb})
        expect(stderr).not_to match(/DEBUG -- : :header => \(Symbol\) :default/)
        expect(stderr).to match(/DEBUG -- : Loaded 3 settings from/)
        expect(stderr).not_to match(/INFO -- : Exiting now because --config-test was specified/)
        expect(stderr).to match(/WARN -- : Failed build_catalog for ./)
        expect(stderr).to match(/OctocatalogDiff::Errors::CatalogError/)
        expect(stderr).to match(/Could not find class (::)?this::module::does::not::exist/)
      end
    end

    context 'when encountering an error in usage' do
      it 'should display error and exit 1' do
        env = { 'OCTOCATALOG_DIFF_CONFIG_FILE' => OctocatalogDiff::Spec.fixture_path('cli-configs/valid.rb') }
        argv = [
          '--bootstrapped-to-dir', OctocatalogDiff::Spec.fixture_path('repos/failing-catalog'),
          '--from-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog.json'),
          '--no-color',
          '--no-hiera-config'
        ]

        cmdline = [script, argv].flatten.map { |x| Shellwords.escape(x) }.join(' ')
        stdout, stderr, status = Open3.capture3(env, cmdline)

        expect(status.exitstatus).to eq(1), [stdout, stderr].join("\n")

        expect(stdout).to eq('')

        expect(stderr).to match(%r{Loading octocatalog-diff configuration from .+/cli-configs/valid.rb})
        expect(stderr).not_to match(/DEBUG -- : :header => \(Symbol\) :default/)
        expect(stderr).to match(/DEBUG -- : Loaded 3 settings from/)
        expect(stderr).not_to match(/INFO -- : Exiting now because --config-test was specified/)
        expect(stderr).to match(/Catalog for 'to' \(.\) failed to compile with/)
        expect(stderr).to match(/ArgumentError: Unable to compute facts for node./)
      end
    end
  end
end
