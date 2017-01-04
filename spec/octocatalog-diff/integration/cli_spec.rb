# frozen_string_literal: true

require_relative '../tests/spec_helper'

require 'open3'
require 'shellwords'

describe 'bin/octocatalog-diff' do
  let(:script) { File.expand_path('../../../bin/octocatalog-diff', File.dirname(__FILE__)) }
  let(:ls_l) { Open3.capture2e("ls -l #{script}").first }
  let(:config_test) { '--config-test' }
  let(:normal_settings) do
    [
      '-d',
      '-n rspec-node.github.net',
      '--fact-file', OctocatalogDiff::Spec.fixture_path('facts/facts.yaml'),
      '--from-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog.json'),
      '--bootstrapped-to-dir', OctocatalogDiff::Spec.fixture_path('repos/default'),
      '--puppet-binary', OctocatalogDiff::Spec::PUPPET_BINARY
    ].map { |x| Shellwords.escape(x) }.join(' ')
  end

  it 'should exist' do
    expect(File.file?(script)).to eq(true), ls_l
  end

  it 'should be executable' do
    expect(File.executable?(script)).to eq(true), ls_l
  end

  context 'with an invalid configuration file' do
    let(:cfg) { OctocatalogDiff::Spec.fixture_path('cli-configs/invalid.rb') }
    let(:env) { { 'OCTOCATALOG_DIFF_CONFIG_FILE' => cfg } }

    it 'should error with --config-test' do
      text, status = Open3.capture2e(env, "#{script} #{config_test}")
      expect(status.exitstatus).to eq(1), text
      expect(text).to match(%r{Loading octocatalog-diff configuration from .+/fixtures/cli-configs/invalid.rb})
      expect(text).to match(/FATAL .+: Fizz Buzz/)
    end

    it 'should error with normal settings' do
      text, status = Open3.capture2e(env, "#{script} #{normal_settings}")
      expect(status.exitstatus).to eq(1), text
      expect(text).to match(%r{Loading octocatalog-diff configuration from .+/fixtures/cli-configs/invalid.rb})
      expect(text).to match(/FATAL .+: Fizz Buzz/)
    end
  end

  context 'with a valid configuration file' do
    let(:cfg) { OctocatalogDiff::Spec.fixture_path('cli-configs/valid.rb') }
    let(:env) { { 'OCTOCATALOG_DIFF_CONFIG_FILE' => cfg } }

    it 'should print values with --config-test and exit' do
      text, status = Open3.capture2e(env, "#{script} #{config_test}")
      expect(status.exitstatus).to eq(0), text
      expect(text).to match(%r{Loading octocatalog-diff configuration from .+/fixtures/cli-configs/valid.rb})
      expect(text).to match(/:header => \(Symbol\) :default/)
      expect(text).to match(%r{:hiera_config => \(String\) "config/hiera.yaml"})
      expect(text).to match(/:hiera_path => \(String\) "hieradata"/)
      expect(text).to match(/Exiting now because --config-test was specified/)
    end

    it 'should print settings details and then invoke the main CLI' do
      text, status = Open3.capture2e(env, "#{script} #{normal_settings}")
      expect(status.exitstatus).to eq(2), text
      expect(text).to match(%r{Loading octocatalog-diff configuration from .+/fixtures/cli-configs/valid.rb})
      expect(text).to match(%r{Loaded 3 settings from .+/fixtures/cli-configs/valid.rb})
      expect(text).to match(/Initialized OctocatalogDiff::Catalog::Computed for to-catalog/)
      expect(text).to match(/Entering catdiff; catalog sizes: 2, 21/)
      expect(text).to match(/Entering filter_diffs_for_absent_files with 14 diffs/)
      expect(text).to match(/Added resources: 14/)
      expect(text).to match(/\+ Ssh_authorized_key\[root@6def27049c06f48eea8b8f37329f40799d07dc84\]/)
    end
  end
end
