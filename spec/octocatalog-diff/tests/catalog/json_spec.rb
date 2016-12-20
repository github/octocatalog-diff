# frozen_string_literal: true

require 'json'

require_relative '../spec_helper'

require OctocatalogDiff::Spec.require_path('/catalog')
require OctocatalogDiff::Spec.require_path('/catalog/json')
require OctocatalogDiff::Spec.require_path('/catalog-util/builddir')

describe OctocatalogDiff::Catalog::JSON do
  context 'with working catalog' do
    before(:all) do
      fixture = OctocatalogDiff::Spec.fixture_path('catalogs/catalog-1.json')
      catalog_opts = { json: File.read(fixture) }
      @catalog_obj = OctocatalogDiff::Catalog::JSON.new(catalog_opts)
    end

    describe '#node' do
      it 'should return node name from catalog' do
        expect(@catalog_obj.node).to eq('my.rspec.node')
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
        expect(@catalog_obj.catalog_json).to eq(File.read(OctocatalogDiff::Spec.fixture_path('catalogs/catalog-1.json')))
      end
    end

    describe '#error_message' do
      it 'should be nil' do
        expect(@catalog_obj.error_message).to eq(nil)
      end
    end
  end

  context 'with failing catalog' do
    before(:all) do
      fixture = OctocatalogDiff::Spec.fixture_path('repos/default/hieradata/common.yaml')
      catalog_opts = { json: File.read(fixture) }
      @catalog_obj = OctocatalogDiff::Catalog::JSON.new(catalog_opts)
    end

    describe '#node' do
      it 'should be nil' do
        expect(@catalog_obj.node).to eq(nil)
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
        expect(@catalog_obj.error_message).to match(/Catalog JSON input failed to parse/)
      end
    end
  end

  context 'other errors' do
    describe '#initialize' do
      it 'should raise ArgumentError if options hash is not passed' do
        expect { _x = OctocatalogDiff::Catalog::JSON.new('foo') }.to raise_error(ArgumentError)
      end

      it 'should raise ArgumentError if content is not passed' do
        expect { _x = OctocatalogDiff::Catalog::JSON.new(bar: 'baz') }.to raise_error(ArgumentError)
      end

      it 'should raise ArgumentError if content is not a string' do
        expect { _x = OctocatalogDiff::Catalog::JSON.new(json: %w(foo bar)) }.to raise_error(ArgumentError)
      end
    end
  end
end
