# This is test coverage for [puppet repo]/lib//facts.rb

require_relative 'spec_helper'
require_relative '../mocks/puppetdb'
require OctocatalogDiff::Spec.require_path('/facts')

describe OctocatalogDiff::Facts do
  context 'facts as YAML string' do
    describe '#initialize' do
      it 'should construct without error with proper arguments' do
        opts = {
          backend: :yaml,
          fact_file_string: File.read(OctocatalogDiff::Spec.fixture_path('facts/facts.yaml'))
        }
        obj = OctocatalogDiff::Facts.new(opts)
        expect(obj).to be_a_kind_of(OctocatalogDiff::Facts)
      end
    end
  end

  context 'facts as JSON string' do
    describe '#initialize' do
      it 'should construct without error with proper arguments' do
        opts = {
          backend: :json,
          fact_file_string: File.read(OctocatalogDiff::Spec.fixture_path('facts/facts.json'))
        }
        obj = OctocatalogDiff::Facts.new(opts)
        expect(obj).to be_a_kind_of(OctocatalogDiff::Facts)
      end
    end
  end

  context 'facts from PuppetDB' do
    describe '#initialize' do
      it 'should construct without error with proper arguments' do
        allow(OctocatalogDiff::PuppetDB).to receive(:new) { |*_arg| OctocatalogDiff::Mocks::PuppetDB.new }
        opts = {
          backend: :puppetdb,
          puppetdb_url: 'https://mocked-puppetdb.somedomain.xyz:8081',
          node: 'valid-facts'
        }
        obj = OctocatalogDiff::Facts.new(opts)
        expect(obj).to be_a_kind_of(OctocatalogDiff::Facts)
      end
    end
  end

  context 'invalid facts backend' do
    describe '#initialize' do
      it 'should raise ArgumentError if invalid facts end is supplied' do
        expect do
          OctocatalogDiff::Facts.new(node: 'foo', backend: :chicken)
        end.to raise_error(ArgumentError, /Invalid fact source backend/)
      end
    end
  end

  context 'fact overrides' do
    it 'should override a non-nil fact' do
      opts = {
        backend: :yaml,
        fact_file_string: File.read(OctocatalogDiff::Spec.fixture_path('facts/facts.yaml'))
      }
      obj = OctocatalogDiff::Facts.new(opts)
      obj.override('architecture', 'new_architecture')
      expect(obj.facts['values']['architecture']).to eq('new_architecture')
    end

    it 'should remove a fact that is nil' do
      opts = {
        backend: :yaml,
        fact_file_string: File.read(OctocatalogDiff::Spec.fixture_path('facts/facts.yaml'))
      }
      obj = OctocatalogDiff::Facts.new(opts)
      obj.override('architecture', nil)
      expect(obj.facts['values'].key?('architecture')).to eq(false)
    end
  end

  context 'test individual methods' do
    before(:all) do
      opts = {
        backend: :yaml,
        fact_file_string: File.read(OctocatalogDiff::Spec.fixture_path('facts/facts.yaml'))
      }
      @obj = OctocatalogDiff::Facts.new(opts)
    end

    describe '#facts' do
      it 'should return facts in proper format' do
        result = @obj.facts
        expect(result).to be_a_kind_of(Hash)
        expect(result['name']).to eq('rspec-node.xyz.github.net')
        expect(result['values']['fqdn']).to eq('rspec-node.xyz.github.net')
      end

      it 'should accept node override' do
        result = @obj.facts('my-node-override')
        expect(result).to be_a_kind_of(Hash)
        expect(result['name']).to eq('my-node-override')
        expect(result['values']['fqdn']).to eq('rspec-node.xyz.github.net')
      end

      it 'should preserve timestamp if asked to do so' do
        result = @obj.facts('my-node-override', true)
        expect(result['timestamp']).to be_a_kind_of(String)
        expect(result['values']['timestamp']).to be_a_kind_of(String)
        expect(result['expiration']).to be_a_kind_of(String)
      end
    end

    describe '#facts_to_yaml' do
      it 'should return facts in proper format' do
        result = @obj.facts_to_yaml
        expect(result).to be_a_kind_of(String)
        result_arr = result.split(/\n/)
        expect(result_arr[0]).to eq('--- !ruby/object:Puppet::Node::Facts')
        expect(result_arr[1].strip).to eq('name: rspec-node.xyz.github.net')
        expect(result_arr[2].strip).to eq('values:')
        expect(result_arr[3].strip).to eq('apt_update_last_success: 1458162123')
      end

      it 'should accept node override' do
        result = @obj.facts_to_yaml('my-node-override')
        expect(result).to be_a_kind_of(String)
        result_arr = result.split(/\n/)
        expect(result_arr[0]).to eq('--- !ruby/object:Puppet::Node::Facts')
        expect(result_arr[1].strip).to eq('name: my-node-override')
        expect(result_arr[2].strip).to eq('values:')
        expect(result_arr[3].strip).to eq('apt_update_last_success: 1458162123')
      end
    end
  end
end
