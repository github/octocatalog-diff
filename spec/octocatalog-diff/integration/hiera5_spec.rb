# frozen_string_literal: true

require_relative 'integration_helper'

module OctocatalogDiff
  class Spec
    def self.hiera5?(puppet_version = ENV['PUPPET_VERSION'])
      if puppet_version.nil?
        raise 'Unable to determine Puppet version used for this test.'
      end
      major_version, minor_version = puppet_version.split('.').map(&:to_i)

      # hiera5 is present in >= 5, absent in <= 3
      return true if major_version >= 5
      return false if major_version <= 3

      # hiera5 was introduced in Puppet 4.9
      minor_version >= 9
    end
  end
end

describe 'repository with hiera 5' do
  context 'with --hiera-path and per-item data directory' do
    it 'should fail because per-item datadir is not supported with --hiera-path' do
      argv = ['-n', 'rspec-node.github.net']
      hash = {
        hiera_config: 'config/hiera5-global.yaml',
        spec_fact_file: 'facts.yaml',
        spec_repo: 'hiera5',
        spec_catalog_old: 'catalog-empty.json'
      }
      result = OctocatalogDiff::Integration.integration(hash.merge(argv: argv))
      expect(result.exitcode).to eq(-1), OctocatalogDiff::Integration.format_exception(result)
      expect(result.exception).to be_a_kind_of(ArgumentError)
      expect(result.exception.message).to match(/Hierarchy item .+ has a datadir/)
    end
  end

  # Even if there's an old hiera version, still test the branch-specific hiera config stuff.
  unless OctocatalogDiff::Spec.hiera5?
    context 'with --to-hiera-config and --from-hiera-config' do
      it 'should succeed in building the catalog' do
        argv = ['-n', 'rspec-node.github.net', '--to-hiera-path', 'hieradata', '--from-hiera-path', 'data']
        hash = {
          hiera_config: 'config/hiera3-global.yaml',
          spec_fact_file: 'facts.yaml',
          spec_repo: 'hiera5',
          spec_catalog_old: 'catalog-empty.json'
        }
        result = OctocatalogDiff::Integration.integration(hash.merge(argv: argv))
        expect(result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(result)

        to_catalog = result.to

        param1 = { 'content' => 'Greets from nodes' }
        expect(to_catalog.resource(type: 'File', title: '/tmp/nodes')['parameters']).to eq(param1)

        param2 = { 'content' => 'Should not be displayed from common' }
        expect(to_catalog.resource(type: 'File', title: '/tmp/special')['parameters']).to eq(param2)

        param3 = { 'content' => 'Greets from common' }
        expect(to_catalog.resource(type: 'File', title: '/tmp/common')['parameters']).to eq(param3)
      end
    end
  end

  # Run these tests for Hiera 5
  if OctocatalogDiff::Spec.hiera5?
    context 'with --hiera-path-strip and per-item data directory' do
      it 'should succeed in building the catalog' do
        argv = ['-n', 'rspec-node.github.net', '--hiera-path-strip', '/var/lib/puppet']
        hash = {
          hiera_config: 'config/hiera5-global.yaml',
          spec_fact_file: 'facts.yaml',
          spec_repo: 'hiera5',
          spec_catalog_old: 'catalog-empty.json'
        }
        result = OctocatalogDiff::Integration.integration(hash.merge(argv: argv))
        expect(result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(result)

        to_catalog = result.to

        # Global configuration overrides environment configuration
        param1 = { 'content' => 'Greets from nodes' }
        expect(to_catalog.resource(type: 'File', title: '/tmp/nodes')['parameters']).to eq(param1)

        param2 = { 'content' => 'Greets from special' }
        expect(to_catalog.resource(type: 'File', title: '/tmp/special')['parameters']).to eq(param2)

        param3 = { 'content' => 'Greets from common' }
        expect(to_catalog.resource(type: 'File', title: '/tmp/common')['parameters']).to eq(param3)

        # Comes from environment because there is no global configuration
        param4 = { 'content' => 'Greets from extra-special' }
        expect(to_catalog.resource(type: 'File', title: '/tmp/extra-special')['parameters']).to eq(param4)
      end
    end

    context 'with hiera 5 non-global, environment specific configuration' do
      it 'should succeed in building the catalog and have proper diffs' do
        argv = ['-n', 'rspec-node.github.net']
        hash = {
          spec_fact_file: 'facts.yaml',
          spec_repo: 'hiera5',
          spec_catalog_old: 'catalog-empty.json'
        }
        result = OctocatalogDiff::Integration.integration(hash.merge(argv: argv))
        expect(result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(result)

        to_catalog = result.to

        # All come from environment
        param1 = { 'content' => 'Greets from data/nodes' }
        expect(to_catalog.resource(type: 'File', title: '/tmp/nodes')['parameters']).to eq(param1)

        param2 = { 'content' => 'Greets from special' }
        expect(to_catalog.resource(type: 'File', title: '/tmp/special')['parameters']).to eq(param2)

        param3 = { 'content' => 'Greets from data/common' }
        expect(to_catalog.resource(type: 'File', title: '/tmp/common')['parameters']).to eq(param3)

        param4 = { 'content' => 'Greets from extra-special' }
        expect(to_catalog.resource(type: 'File', title: '/tmp/extra-special')['parameters']).to eq(param4)
      end
    end

    # May be used to catalog-diff an upgrade from Hiera 3 to Hiera 5
    context 'with --from-hiera-config and --to-hiera-config' do
      it 'should succeed in building the catalog and have proper diffs' do
        argv = [
          '-n', 'rspec-node.github.net',
          '--from-hiera-config', 'config/hiera3-global.yaml',
          '--from-hiera-path', 'data',
          '--to-hiera-config', 'config/hiera5-global.yaml',
          '--to-hiera-path-strip', '/var/lib/puppet'
        ]
        hash = {
          spec_fact_file: 'facts.yaml',
          spec_repo: 'hiera5'
        }
        result = OctocatalogDiff::Integration.integration(hash.merge(argv: argv))
        expect(result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(result)
        expect(result.diffs.size).to eq(3)

        diff1 = {
          diff_type: '~',
          type: 'File',
          title: '/tmp/special',
          structure: %w(parameters content),
          old_value: 'Should not be displayed from common',
          new_value: 'Greets from special'
        }
        expect(OctocatalogDiff::Spec.diff_match?(result.diffs, diff1)).to eq(true)

        diff2 = {
          diff_type: '~',
          type: 'File',
          title: '/tmp/nodes',
          structure: %w(parameters content),
          old_value: 'Greets from data/nodes',
          new_value: 'Greets from nodes'
        }
        expect(OctocatalogDiff::Spec.diff_match?(result.diffs, diff2)).to eq(true)

        diff3 = {
          diff_type: '~',
          type: 'File',
          title: '/tmp/common',
          structure: %w(parameters content),
          old_value: 'Greets from data/common',
          new_value: 'Greets from common'
        }
        expect(OctocatalogDiff::Spec.diff_match?(result.diffs, diff3)).to eq(true)

        # Even with a hiera 3 global file, Puppet 4.9 will start to recognize `<root dir>/hiera.yaml`
        # so there is no difference reported for the "extra-special" hiera setup.
      end
    end

    # May be used to catalog-diff a migration from a global hiera file to an environment level one
    context 'with --from-hiera-config' do
      it 'should succeed in building the catalog and have proper diffs' do
        argv = [
          '-n', 'rspec-node.github.net',
          '--from-hiera-config', 'config/hiera5-global.yaml',
          '--from-hiera-path-strip', '/var/lib/puppet'
        ]
        hash = {
          spec_fact_file: 'facts.yaml',
          spec_repo: 'hiera5'
        }
        result = OctocatalogDiff::Integration.integration(hash.merge(argv: argv))
        expect(result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(result)
        expect(result.diffs.size).to eq(2)

        diff1 = {
          diff_type: '~',
          type: 'File',
          title: '/tmp/common',
          structure: %w(parameters content),
          old_value: 'Greets from common',
          new_value: 'Greets from data/common'
        }
        expect(OctocatalogDiff::Spec.diff_match?(result.diffs, diff1)).to eq(true)

        diff2 = {
          diff_type: '~',
          type: 'File',
          title: '/tmp/nodes',
          structure: %w(parameters content),
          old_value: 'Greets from nodes',
          new_value: 'Greets from data/nodes'
        }
        expect(OctocatalogDiff::Spec.diff_match?(result.diffs, diff2)).to eq(true)
      end
    end
  end
end
