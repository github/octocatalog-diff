# frozen_string_literal: true

require_relative 'integration_helper'

describe 'repository with hiera 5' do
  context 'with --hiera-path and per-item data directory' do
    it 'should fail because per-item datadir is not supported with --hiera-path' do
      argv = ['-n', 'rspec-node.github.net']
      hash = { hiera_config: 'config/hiera5-global.yaml', spec_fact_file: 'facts.yaml', spec_repo: 'hiera5' }
      result = OctocatalogDiff::Integration.integration(hash.merge(argv: argv))
      expect(result.exitcode).to eq(-1), OctocatalogDiff::Integration.format_exception(result)
      expect(result.exception).to be_a_kind_of(ArgumentError)
      expect(result.exception.message).to match(/Hierarchy item .+ has a datadir/)
    end
  end
end
