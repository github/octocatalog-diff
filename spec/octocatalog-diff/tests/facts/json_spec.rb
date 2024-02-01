# frozen_string_literal: true

# This is test coverage for [puppet repo]/lib//facts/json.rb

require_relative '../spec_helper'
require OctocatalogDiff::Spec.require_path('/facts/yaml')

require 'json'

describe OctocatalogDiff::Facts::JSON do
  describe '#fact_retriever' do
    it 'should load facts' do
      fact_file = OctocatalogDiff::Spec.fixture_path('facts/facts.json')
      options = {
        fact_file_string: File.read(fact_file)
      }
      result = OctocatalogDiff::Facts::JSON.fact_retriever(options)
      expect(result).to be_a_kind_of(Hash)
      expect(result['name']).to eq('rspec-node.xyz.github.net')
      expect(result['values']['fqdn']).to eq('rspec-node.xyz.github.net')
    end

    it 'should fail if input is not JSON' do
      options = {
        fact_file_string: 'This certainly is not valid JSON'
      }
      expect do
        OctocatalogDiff::Facts::JSON.fact_retriever(options)
      end.to raise_error(JSON::ParserError)
    end

    it 'should override the node from facts' do
      fact_file = OctocatalogDiff::Spec.fixture_path('facts/facts.json')
      options = {
        fact_file_string: File.read(fact_file)
      }
      result = OctocatalogDiff::Facts::JSON.fact_retriever(options, 'override.node')
      expect(result).to be_a_kind_of(Hash)
      expect(result['name']).to eq('override.node')
      expect(result['values']['fqdn']).to eq('rspec-node.xyz.github.net')
    end

    it 'should fill in a missing name from hash with name/values' do
      fact_file = OctocatalogDiff::Spec.fixture_path('facts/encoded-facts.json')
      data = JSON.parse(File.read(fact_file))
      data['name'] = ''
      options = {
        fact_file_string: JSON.generate(data)
      }
      result = OctocatalogDiff::Facts::JSON.fact_retriever(options)
      expect(result).to be_a_kind_of(Hash)
      expect(result['name']).to eq('rspec-node.xyz.github.net')
      expect(result['values']['fqdn']).to eq('rspec-node.xyz.github.net')
    end

    it 'should not double-encode hash already containing name and values' do
      fact_file = OctocatalogDiff::Spec.fixture_path('facts/encoded-facts.json')
      options = {
        fact_file_string: File.read(fact_file)
      }
      result = OctocatalogDiff::Facts::JSON.fact_retriever(options)
      expect(result).to be_a_kind_of(Hash)
      expect(result.keys).to match_array(%w(name values))
      expect(result['name']).to eq('rspec-node.abc.github.net')
      expect(result['values']['fqdn']).to eq('rspec-node.xyz.github.net')
    end
  end
end
