# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_fact_file' do
    it 'should read facts from a YAML file' do
      fact_file = OctocatalogDiff::Spec.fixture_path('facts/facts.yaml')
      result = run_optparse(['--fact-file', fact_file])
      expect(result[:node]).to eq('rspec-node.xyz.github.net')
      result_facts = result[:facts].facts
      expect(result_facts).to be_a_kind_of(Hash)
      expect(result_facts['name']).to eq('rspec-node.xyz.github.net')
      expect(result_facts['values']).to be_a_kind_of(Hash)
      expect(result_facts['values']['fqdn']).to eq('rspec-node.xyz.github.net')
      expect(result_facts['values'].keys).not_to include('expiration')
    end

    it 'should read facts from a JSON file' do
      fact_file = OctocatalogDiff::Spec.fixture_path('facts/facts.json')
      result = run_optparse(['--fact-file', fact_file])
      expect(result[:node]).to eq('rspec-node.xyz.github.net')
      result_facts = result[:facts].facts
      expect(result_facts).to be_a_kind_of(Hash)
      expect(result_facts['name']).to eq('rspec-node.xyz.github.net')
      expect(result_facts['values']).to be_a_kind_of(Hash)
      expect(result_facts['values']['fqdn']).to eq('rspec-node.xyz.github.net')
      expect(result_facts['values'].keys).not_to include('expiration')
    end

    it 'should accept an override of the node' do
      fact_file = OctocatalogDiff::Spec.fixture_path('facts/facts.json')
      result = run_optparse(['--fact-file', fact_file], node: 'octonode.rspec')
      expect(result[:node]).to eq('octonode.rspec')
    end

    it 'should throw error for unrecognized extension' do
      expect do
        fact_file = OctocatalogDiff::Spec.fixture_path('facts/facts.foo')
        run_optparse(['--fact-file', fact_file])
      end.to raise_error(ArgumentError)
    end

    it 'should throw error if file is not found' do
      expect do
        fact_file = OctocatalogDiff::Spec.fixture_path('facts/facts.not.existing')
        run_optparse(['--fact-file', fact_file])
      end.to raise_error(Errno::ENOENT)
    end
  end
end
