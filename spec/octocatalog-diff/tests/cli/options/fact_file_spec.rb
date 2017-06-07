# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_fact_file' do
    it 'should read facts from a YAML file' do
      fact_file = OctocatalogDiff::Spec.fixture_path('facts/facts.yaml')
      result = run_optparse(['--fact-file', fact_file])
      expect(result[:node]).to eq('rspec-node.xyz.github.net')
      result_facts = result[:to_facts].facts
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
      result_facts = result[:to_facts].facts
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

  describe '#opt_to_fact_file' do
    let(:fact_file) { OctocatalogDiff::Spec.fixture_path('facts/facts.yaml') }
    let(:fact_answer) do
      {
        'name' => 'rspec-node.xyz.github.net',
        'values' => {
          'apt_update_last_success' => 1_458_162_123,
          'architecture' => 'amd64',
          'datacenter' => 'xyz',
          'fqdn' => 'rspec-node.xyz.github.net'
        }
      }
    end

    it 'should distinguish between the to-facts and from-facts' do
      fact_file_1 = OctocatalogDiff::Spec.fixture_path('facts/facts.yaml')
      fact_file_2 = OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml')
      result = run_optparse(['--from-fact-file', fact_file_1, '--to-fact-file', fact_file_2])

      result_facts_1 = result[:from_facts].facts
      expect(result_facts_1).to be_a_kind_of(Hash)
      expect(result_facts_1['name']).to eq('rspec-node.xyz.github.net')
      expect(result_facts_1['values']).to be_a_kind_of(Hash)
      expect(result_facts_1['values']['fqdn']).to eq('rspec-node.xyz.github.net')
      expect(result_facts_1['values']['ipaddress']).to be_nil
      expect(result_facts_1['values'].keys).not_to include('expiration')

      result_facts_2 = result[:to_facts].facts
      expect(result_facts_2).to be_a_kind_of(Hash)
      expect(result_facts_2['name']).to eq('rspec-node.xyz.github.net')
      expect(result_facts_2['values']).to be_a_kind_of(Hash)
      expect(result_facts_2['values']['fqdn']).to eq('rspec-node.xyz.github.net')
      expect(result_facts_2['values']['ipaddress']).to eq('10.20.30.40')
      expect(result_facts_2['values'].keys).not_to include('expiration')
    end

    it 'should only define from-fact-file when only --from-fact-file is given' do
      result = run_optparse(['--from-fact-file', fact_file])
      expect(result[:from_facts].facts).to eq(fact_answer)
      expect(result[:to_facts]).to be_nil
    end

    it 'should only define to-fact-file when only --to-fact-file is given' do
      result = run_optparse(['--from-fact-file', fact_file])
      expect(result[:from_facts]).to be_nil
      expect(result[:to_facts].facts).to eq(fact_answer)
    end

    it 'should define both from and to fact file when --fact-file is given' do
      result = run_optparse(['--fact-file', fact_file])
      expect(result[:from_facts].facts).to eq(fact_answer)
      expect(result[:to_facts].facts).to eq(fact_answer)
    end
  end
end
