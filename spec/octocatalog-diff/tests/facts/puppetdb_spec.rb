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
        node: 'valid-facts',
        puppetdb_package_inventory: true
      }
    end

    describe '#fact_retriever' do
      it 'should retrieve facts for the valid-facts node' do
        node = 'valid-facts'
        fact_obj = OctocatalogDiff::Facts::PuppetDB.fact_retriever(@opts, node)
        expect(fact_obj).to be_a_kind_of(Hash)
        expect(fact_obj['name']).to eq(node)
        expect(fact_obj['values']['fqdn']).to eq('rspec-node.xyz.github.net')
        expect(fact_obj['values']['_puppet_packages_1']).to be_nil
      end

      it 'should catch and handle error for non-existent host' do
        node = 'fjoaewjroisajdfoisdjfaojeworjsdofjsdofawejr'
        expect do
          OctocatalogDiff::Facts::PuppetDB.fact_retriever(@opts, node)
        end.to raise_error(OctocatalogDiff::Errors::FactRetrievalError)
      end

      it 'should retrieve packages for the valid-packages node' do
        node = 'valid-packages'
        fact_obj = OctocatalogDiff::Facts::PuppetDB.fact_retriever(@opts, node)
        expect(fact_obj).to be_a_kind_of(Hash)
        expect(fact_obj['name']).to eq(node)
        expect(fact_obj['values']['_puppet_inventory_1']).to be_a_kind_of(Hash)
        expect(fact_obj['values']['_puppet_inventory_1']['packages']).to be_a_kind_of(Array)
        expect(fact_obj['values']['_puppet_inventory_1']['packages']).to eq(
          [
            ['kernel', '3.2.1', 'yum'],
            ['bash', '4.0.0', 'yum']
          ]
        )
      end
    end
  end

  context 'PuppetDB API compatibility layer' do
    before(:each) do
      clazz = double('OctocatalogDiff::PuppetDB')
      allow(clazz).to receive(:get) do |args|
        if args =~ /package-inventory/
          packages
        else
          [{ 'certname' => 'foo.bar.com', 'name' => 'uri', 'value' => args }]
        end
      end
      allow(OctocatalogDiff::PuppetDB).to receive(:new).and_return(clazz)
    end

    let(:packages) { [] }

    it 'should use the correct URL for API v3' do
      opts = {
        puppetdb_api_version: 3,
        puppetdb_package_inventory: true,
        puppetdb_url: 'https://foo.bar.baz:8081'
      }
      result = OctocatalogDiff::Facts::PuppetDB.fact_retriever(opts, 'foo.bar.com')
      expect(result).to eq('name' => 'foo.bar.com', 'values' => { 'uri' => '/v3/nodes/foo.bar.com/facts' })
    end

    it 'should use the correct URL for API v4' do
      opts = {
        puppetdb_api_version: 4,
        puppetdb_package_inventory: true,
        puppetdb_url: 'https://foo.bar.baz:8081'
      }
      result = OctocatalogDiff::Facts::PuppetDB.fact_retriever(opts, 'foo.bar.com')
      expect(result).to eq('name' => 'foo.bar.com', 'values' => { 'uri' => '/pdb/query/v4/nodes/foo.bar.com/facts' })
    end

    it 'should default to API v4' do
      opts = {
        puppetdb_package_inventory: true,
        puppetdb_url: 'https://foo.bar.baz:8081'
      }
      result = OctocatalogDiff::Facts::PuppetDB.fact_retriever(opts, 'foo.bar.com')
      expect(result).to eq('name' => 'foo.bar.com', 'values' => { 'uri' => '/pdb/query/v4/nodes/foo.bar.com/facts' })
    end

    it 'should fail if an unrecognized API version is provided' do
      opts = {
        puppetdb_api_version: 9000,
        puppetdb_package_inventory: true,
        puppetdb_url: 'https://foo.bar.baz:8081'
      }
      expect { OctocatalogDiff::Facts::PuppetDB.fact_retriever(opts, 'foo.bar.com') }.to raise_error(KeyError)
    end

    context 'when packages returns data' do
      let(:packages) do
        [
          {
            'certname' => 'foo.bar.com',
            'package_name' => 'foo',
            'version' => '1.2.3',
            'provider' => 'yum'
          },
          {
            'certname' => 'foo.bar.com',
            'package_name' => 'kernel',
            'version' => '3.2.1',
            'provider' => 'yum'
          },
          {
            'certname' => 'foo.bar.com',
            'package_name' => 'kernel',
            'version' => '3.2.2',
            'provider' => 'yum'
          }
        ]
      end

      it 'should return packages when puppetdb_package_inventory is enabled' do
        opts = {
          puppetdb_url: 'https://foo.bar.baz:8081',
          puppetdb_package_inventory: true
        }
        result = OctocatalogDiff::Facts::PuppetDB.fact_retriever(opts, 'foo.bar.com')
        expect(result).to eq(
          'name' => 'foo.bar.com',
          'values' => {
            'uri' => '/pdb/query/v4/nodes/foo.bar.com/facts',
            '_puppet_inventory_1' => {
              'packages' => [
                ['foo', '1.2.3', 'yum'],
                ['kernel', '3.2.1; 3.2.2', 'yum']
              ]
            }
          }
        )
      end

      it 'should not return packages when puppetdb_package_inventory is false' do
        opts = {
          puppetdb_package_inventory: false,
          puppetdb_url: 'https://foo.bar.baz:8081'
        }
        result = OctocatalogDiff::Facts::PuppetDB.fact_retriever(opts, 'foo.bar.com')
        expect(result).to eq(
          'name' => 'foo.bar.com',
          'values' => {
            'uri' => '/pdb/query/v4/nodes/foo.bar.com/facts'
          }
        )
      end
    end
  end

  context 'mocking methods for error testing' do
    describe '#fact_retriever' do
      context 'error during fact retrieval' do
        let(:opts) { { puppetdb_url: 'https://mocked-puppetdb.somedomain.xyz:8081', node: 'valid-facts' } }
        let(:node) { 'valid-facts' }

        it 'should handle OctocatalogDiff::Errors::PuppetDBConnectionError' do
          obj = double('OctocatalogDiff::PuppetDB')
          allow(obj).to receive(:get).and_raise(OctocatalogDiff::Errors::PuppetDBConnectionError, 'test message')
          allow(OctocatalogDiff::PuppetDB).to receive(:new) { |*_arg| obj }
          expect do
            OctocatalogDiff::Facts::PuppetDB.fact_retriever(opts, node)
          end.to raise_error(OctocatalogDiff::Errors::FactSourceError, /Fact retrieval failed \(.*ConnectionError\) \(test/)
        end

        it 'should handle OctocatalogDiff::Errors::PuppetDBNodeNotFoundError' do
          obj = double('OctocatalogDiff::PuppetDB')
          allow(obj).to receive(:get).and_raise(OctocatalogDiff::Errors::PuppetDBNodeNotFoundError, 'test message')
          allow(OctocatalogDiff::PuppetDB).to receive(:new) { |*_arg| obj }
          expect do
            OctocatalogDiff::Facts::PuppetDB.fact_retriever(opts, node)
          end.to raise_error(OctocatalogDiff::Errors::FactRetrievalError, /Node valid-facts not found in PuppetDB \(test/)
        end

        it 'should handle OctocatalogDiff::Errors::PuppetDBGenericError' do
          obj = double('OctocatalogDiff::PuppetDB')
          allow(obj).to receive(:get).and_raise(OctocatalogDiff::Errors::PuppetDBGenericError, 'test message')
          allow(OctocatalogDiff::PuppetDB).to receive(:new) { |*_arg| obj }
          expect do
            OctocatalogDiff::Facts::PuppetDB.fact_retriever(opts, node)
          end.to raise_error(OctocatalogDiff::Errors::FactRetrievalError, /Fact retrieval failed for node valid-facts/)
        end
      end

      context 'error during package inventory retrieval' do
        before(:each) do
          allow(OctocatalogDiff::PuppetDB).to receive(:new) { |*_arg| puppetdb }
        end

        let(:opts) do
          {
            puppetdb_url: 'https://mocked-puppetdb.somedomain.xyz:8081',
            node: 'valid-packages',
            puppetdb_package_inventory: true
          }
        end
        let(:node) { 'valid-packages' }
        let(:puppetdb) { OctocatalogDiff::Mocks::PuppetDB.new }

        it 'should handle OctocatalogDiff::Errors::PuppetDBConnectionError' do
          allow(puppetdb).to receive(:get).and_wrap_original do |m, *args|
            if args[0] =~ %r{/package-inventory/}
              raise(OctocatalogDiff::Errors::PuppetDBConnectionError, 'test message')
            else
              m.call(*args)
            end
          end

          expect do
            OctocatalogDiff::Facts::PuppetDB.fact_retriever(opts, node)
          end.to raise_error(
            OctocatalogDiff::Errors::FactSourceError, /Package inventory retrieval failed \(.*ConnectionError\) \(test/
          )
        end

        it 'should handle OctocatalogDiff::Errors::PuppetDBNodeNotFoundError' do
          allow(puppetdb).to receive(:get).and_wrap_original do |m, *args|
            if args[0] =~ %r{/package-inventory/}
              raise(OctocatalogDiff::Errors::PuppetDBNodeNotFoundError, 'test message')
            else
              m.call(*args)
            end
          end
          expect(OctocatalogDiff::Facts::PuppetDB.fact_retriever(opts, node)).to be_a_kind_of(Hash)
        end

        it 'should handle OctocatalogDiff::Errors::PuppetDBGenericError' do
          allow(puppetdb).to receive(:get).and_wrap_original do |m, *args|
            if args[0] =~ %r{/package-inventory/}
              raise(OctocatalogDiff::Errors::PuppetDBGenericError, 'test message')
            else
              m.call(*args)
            end
          end
          expect do
            OctocatalogDiff::Facts::PuppetDB.fact_retriever(opts, node)
          end.to raise_error(
            OctocatalogDiff::Errors::FactRetrievalError, /Package inventory retrieval failed for node valid-packages/
          )
        end
      end
    end
  end
end
