# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../mocks/puppetdb'
require OctocatalogDiff::Spec.require_path('/errors')
require OctocatalogDiff::Spec.require_path('/facts/puppetdb')

describe OctocatalogDiff::Facts::PuppetDB do
  context 'using mocked puppetdb' do
    before(:each) do
      allow(OctocatalogDiff::PuppetDB).to receive(:new) { |*_arg| OctocatalogDiff::Mocks::PuppetDB.new }
      @opts = {
        puppetdb_url: 'https://mocked-puppetdb.somedomain.xyz:8081',
        node: 'valid-facts'
      }
    end

    describe '#fact_retriever' do
      it 'should retrieve facts for the valid-facts node' do
        node = 'valid-facts'
        fact_obj = OctocatalogDiff::Facts::PuppetDB.fact_retriever(@opts, node)
        expect(fact_obj).to be_a_kind_of(Hash)
        expect(fact_obj['name']).to eq(node)
        expect(fact_obj['values']['fqdn']).to eq('rspec-node.xyz.github.net')
      end

      it 'should catch and handle error for non-existent host' do
        node = 'fjoaewjroisajdfoisdjfaojeworjsdofjsdofawejr'
        expect do
          OctocatalogDiff::Facts::PuppetDB.fact_retriever(@opts, node)
        end.to raise_error(OctocatalogDiff::Errors::FactRetrievalError)
      end
    end
  end

  context 'PuppetDB API compatibility layer' do
    before(:each) do
      clazz = double('OctocatalogDiff::PuppetDB')
      allow(clazz).to receive(:get) { |args| [{ 'certname' => 'foo.bar.com', 'name' => 'uri', 'value' => args }] }
      allow(OctocatalogDiff::PuppetDB).to receive(:new).and_return(clazz)
    end

    it 'should use the correct URL for API v3' do
      opts = {
        puppetdb_api_version: 3,
        puppetdb_url: 'https://foo.bar.baz:8081'
      }
      result = OctocatalogDiff::Facts::PuppetDB.fact_retriever(opts, 'foo.bar.com')
      expect(result).to eq('name' => 'foo.bar.com', 'values' => { 'uri' => '/v3/nodes/foo.bar.com/facts' })
    end

    it 'should use the correct URL for API v4' do
      opts = {
        puppetdb_api_version: 4,
        puppetdb_url: 'https://foo.bar.baz:8081'
      }
      result = OctocatalogDiff::Facts::PuppetDB.fact_retriever(opts, 'foo.bar.com')
      expect(result).to eq('name' => 'foo.bar.com', 'values' => { 'uri' => '/pdb/query/v4/nodes/foo.bar.com/facts' })
    end

    it 'should default to API v4' do
      opts = {
        puppetdb_url: 'https://foo.bar.baz:8081'
      }
      result = OctocatalogDiff::Facts::PuppetDB.fact_retriever(opts, 'foo.bar.com')
      expect(result).to eq('name' => 'foo.bar.com', 'values' => { 'uri' => '/pdb/query/v4/nodes/foo.bar.com/facts' })
    end

    it 'should fail if an unrecognized API version is provided' do
      opts = {
        puppetdb_api_version: 9000,
        puppetdb_url: 'https://foo.bar.baz:8081'
      }
      expect { OctocatalogDiff::Facts::PuppetDB.fact_retriever(opts, 'foo.bar.com') }.to raise_error(KeyError)
    end
  end

  context 'mocking methods for error testing' do
    describe '#fact_retriever' do
      let(:opts) { { puppetdb_url: 'https://mocked-puppetdb.somedomain.xyz:8081', node: 'valid-facts' } }
      let(:node) { 'valid-facts' }

      it 'should handle OctocatalogDiff::PuppetDB::ConnectionError' do
        obj = double('OctocatalogDiff::PuppetDB')
        allow(obj).to receive(:get).and_raise(OctocatalogDiff::PuppetDB::ConnectionError, 'test message')
        allow(OctocatalogDiff::PuppetDB).to receive(:new) { |*_arg| obj }
        expect do
          OctocatalogDiff::Facts::PuppetDB.fact_retriever(opts, node)
        end.to raise_error(OctocatalogDiff::Errors::FactSourceError, /Fact retrieval failed \(.*ConnectionError\) \(test/)
      end

      it 'should handle OctocatalogDiff::PuppetDB::NotFoundError' do
        obj = double('OctocatalogDiff::PuppetDB')
        allow(obj).to receive(:get).and_raise(OctocatalogDiff::PuppetDB::NotFoundError, 'test message')
        allow(OctocatalogDiff::PuppetDB).to receive(:new) { |*_arg| obj }
        expect do
          OctocatalogDiff::Facts::PuppetDB.fact_retriever(opts, node)
        end.to raise_error(OctocatalogDiff::Errors::FactRetrievalError, /Node valid-facts not found in PuppetDB \(test/)
      end

      it 'should handle OctocatalogDiff::PuppetDB::PuppetDBError' do
        obj = double('OctocatalogDiff::PuppetDB')
        allow(obj).to receive(:get).and_raise(OctocatalogDiff::PuppetDB::PuppetDBError, 'test message')
        allow(OctocatalogDiff::PuppetDB).to receive(:new) { |*_arg| obj }
        expect do
          OctocatalogDiff::Facts::PuppetDB.fact_retriever(opts, node)
        end.to raise_error(OctocatalogDiff::Errors::FactRetrievalError, /Fact retrieval failed for node valid-facts/)
      end
    end
  end
end
