# frozen_string_literal: true

# This is test coverage for [puppet repo]/lib//facts/yaml.rb

require_relative '../spec_helper'
require OctocatalogDiff::Spec.require_path('/facts/yaml')

describe OctocatalogDiff::Facts::Yaml do
  describe '#fact_retriever' do
    it 'should load facts' do
      fact_file = OctocatalogDiff::Spec.fixture_path('facts/facts.yaml')
      options = {
        fact_file_string: File.read(fact_file)
      }
      result = OctocatalogDiff::Facts::Yaml.fact_retriever(options)
      expect(result).to be_a_kind_of(Hash)
      expect(result['name']).to eq('rspec-node.xyz.github.net')
      expect(result['values']['fqdn']).to eq('rspec-node.xyz.github.net')
    end

    it 'should fail if input is not YAML' do
      options = {
        fact_file_string: "---\nthis: is: not: valid:\n-yaml\n  -yaml\n    -yaml\n"
      }
      expect do
        OctocatalogDiff::Facts::Yaml.fact_retriever(options)
      end.to raise_error(Psych::SyntaxError)
    end

    it 'should override the node from facts' do
      fact_file = OctocatalogDiff::Spec.fixture_path('facts/facts.yaml')
      options = {
        fact_file_string: File.read(fact_file)
      }
      result = OctocatalogDiff::Facts::Yaml.fact_retriever(options, 'override.node')
      expect(result).to be_a_kind_of(Hash)
      expect(result['name']).to eq('override.node')
      expect(result['values']['fqdn']).to eq('rspec-node.xyz.github.net')
    end

    it 'should convert unstructured facts into structured facts' do
      fact_file = OctocatalogDiff::Spec.fixture_path('facts/unstructured.yaml')
      options = {
        fact_file_string: File.read(fact_file)
      }
      result = OctocatalogDiff::Facts::Yaml.fact_retriever(options, 'override.node')
      expect(result).to be_a_kind_of(Hash)
      expect(result['name']).to eq('override.node')
      expect(result['values']['fqdn']).to eq('rspec-node.xyz.github.net')
      expect(result['values']['ec2_metadata']['block-device-mapping']['ephemeral0']).to eq('sdb')
    end
  end
end
