# frozen_string_literal: true

require_relative 'integration_helper'

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

  if ENV['PUPPET_VERSION'] && ENV['PUPPET_VERSION'].start_with?('3')
    # Hiera 5 tests are not applicable
  else
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
