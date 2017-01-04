# frozen_string_literal: true

require_relative 'integration_helper'
require 'json'

describe 'YAML file suppression for identical diffs' do
  let(:argv) { ['-n', 'rspec-node.github.net', '--to-fact-override', 'role=bar'] }
  let(:hash) do
    {
      hiera_config: 'hiera.yaml',
      spec_fact_file: 'facts.yaml',
      spec_repo: 'yaml-diff'
    }
  end

  context 'with YAML diff suppression disabled' do
    let(:result) { OctocatalogDiff::Integration.integration(hash.merge(argv: argv)) }

    it 'should compile without error' do
      expect(result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(result)
      expect(result.exception).to be_nil
    end
  end

  context 'with YAML diff suppression enabled' do
    let(:result) { OctocatalogDiff::Integration.integration(hash.merge(argv: argv + ['--ignore-yaml-whitespace'])) }

    it 'should compile without error' do
      expect(result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(result)
      expect(result.exception).to be_nil
    end
  end
end
