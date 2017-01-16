# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../mocks/puppetdb'

require 'json'

require OctocatalogDiff::Spec.require_path('/catalog')
require OctocatalogDiff::Spec.require_path('/catalog/puppetdb')
require OctocatalogDiff::Spec.require_path('/catalog-util/builddir')
require OctocatalogDiff::Spec.require_path('/errors')

describe OctocatalogDiff::Catalog::PuppetDB do
  context 'with working catalog' do
    before(:each) do
      allow(OctocatalogDiff::PuppetDB).to receive(:new) { |*_arg| OctocatalogDiff::Mocks::PuppetDB.new }
      catalog_opts = { node: 'tiny-catalog-2-puppetdb' }
      @catalog_obj = OctocatalogDiff::Catalog::PuppetDB.new(catalog_opts)
      @catalog_obj.build
    end

    describe '#node' do
      it 'should return node name from catalog' do
        expect(@catalog_obj.node).to eq('tiny-catalog-2-puppetdb')
      end
    end

    describe '#catalog' do
      it 'should return catalog structure' do
        expect(@catalog_obj.catalog).to be_a_kind_of(Hash)
        expect(@catalog_obj.catalog['document_type']).to eq('Catalog')
      end
    end

    describe '#catalog_json' do
      it 'should return correct JSON as strong' do
        content = File.read(OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog-2-puppetdb-converted.json'))
        expect(@catalog_obj.catalog_json).to eq(content)
      end
    end

    describe '#error_message' do
      it 'should be nil' do
        expect(@catalog_obj.error_message).to eq(nil)
      end
    end
  end

  context 'with missing node' do
    before(:each) do
      allow(OctocatalogDiff::PuppetDB).to receive(:new) { |*_arg| OctocatalogDiff::Mocks::PuppetDB.new }
      catalog_opts = {
        puppetdb: OctocatalogDiff::Mocks::PuppetDB.new,
        node: 'asdfdsafasdfasd'
      }
      @catalog_obj = OctocatalogDiff::Catalog::PuppetDB.new(catalog_opts)
      @catalog_obj.build
    end

    describe '#node' do
      it 'should match input' do
        expect(@catalog_obj.node).to eq('asdfdsafasdfasd')
      end
    end

    describe '#catalog' do
      it 'should be nil' do
        expect(@catalog_obj.catalog).to eq(nil)
      end
    end

    describe '#catalog_json' do
      it 'should be nil' do
        expect(@catalog_obj.catalog_json).to eq(nil)
      end
    end

    describe '#error_message' do
      it 'should have parse error' do
        expect(@catalog_obj.error_message).to match(/Node asdfdsafasdfasd not found in PuppetDB/)
      end
    end
  end

  context 'other errors' do
    before(:each) do
      allow(OctocatalogDiff::PuppetDB).to receive(:new) { |*_arg| OctocatalogDiff::Mocks::PuppetDB.new }
    end

    describe '#initialize' do
      it 'should raise ArgumentError if options hash is not passed' do
        expect { _x = OctocatalogDiff::Catalog::PuppetDB.new('foo') }.to raise_error(ArgumentError)
      end

      it 'should raise ArgumentError if node is not a string' do
        expect { _x = OctocatalogDiff::Catalog::PuppetDB.new(node: %w(foo)) }.to raise_error(ArgumentError)
      end
    end
  end

  context 'fetch errors' do
    describe '#fetch_catalog' do
      before(:each) do
        @obj = OctocatalogDiff::Catalog::PuppetDB.new(node: 'foo')
        @logger, @logger_str = OctocatalogDiff::Spec.setup_logger
      end

      it 'should set error message for connection error' do
        puppetdb = double('OctocatalogDiff::PuppetDB')
        allow(puppetdb).to receive(:get).and_raise(OctocatalogDiff::Errors::PuppetDBConnectionError, 'test')
        allow(OctocatalogDiff::PuppetDB).to receive(:new).and_return(puppetdb)

        @obj.send(:fetch_catalog, @logger)
        expect(@obj.error_message).to match(/Catalog retrieval failed \(.*::PuppetDBConnectionError\) \(test\)/)
      end

      it 'should set error message for not found error' do
        puppetdb = double('OctocatalogDiff::PuppetDB')
        allow(puppetdb).to receive(:get).and_raise(OctocatalogDiff::Errors::PuppetDBNodeNotFoundError, 'test')
        allow(OctocatalogDiff::PuppetDB).to receive(:new).and_return(puppetdb)

        @obj.send(:fetch_catalog, @logger)
        expect(@obj.error_message).to match(/Node foo not found in PuppetDB \(test\)/)
      end

      it 'should set error message for puppetdb error' do
        puppetdb = double('OctocatalogDiff::PuppetDB')
        allow(puppetdb).to receive(:get).and_raise(OctocatalogDiff::Errors::PuppetDBGenericError, 'test')
        allow(OctocatalogDiff::PuppetDB).to receive(:new).and_return(puppetdb)

        @obj.send(:fetch_catalog, @logger)
        expect(@obj.error_message).to match(/Catalog retrieval failed for node foo from PuppetDB \(test\)/)
      end

      it 'should set error message for JSON generator error' do
        allow(JSON).to receive(:generate).and_raise(JSON::GeneratorError, 'test')
        allow(OctocatalogDiff::PuppetDB).to receive(:new) { |*_arg| OctocatalogDiff::Mocks::PuppetDB.new }
        obj = OctocatalogDiff::Catalog::PuppetDB.new(node: 'tiny-catalog-2-puppetdb')
        logger, _logger_str = OctocatalogDiff::Spec.setup_logger
        obj.send(:fetch_catalog, logger)
        expect(obj.error_message).to match(/Failed to generate result from PuppetDB as JSON \(test\)/)
      end
    end
  end
end
