# frozen_string_literal: true

require_relative '../../spec_helper'

require OctocatalogDiff::Spec.require_path('/catalog')
require OctocatalogDiff::Spec.require_path('/api/v1/catalog')

describe OctocatalogDiff::API::V1::Catalog do
  context 'with a non-catalog' do
    describe '#initialize' do
      it 'should raise ArgumentError' do
        expect { described_class.new(nil) }.to raise_error(ArgumentError)
      end
    end
  end

  context 'with a valid catalog' do
    before(:all) do
      @catalog = OctocatalogDiff::Catalog.new(json: OctocatalogDiff::Spec.fixture_read('catalogs/catalog-1.json'))
      @testobj = described_class.new(@catalog)
    end

    describe '#initialize' do
      it 'should set @raw' do
        expect(@testobj.raw).to eq(@catalog)
      end
    end

    describe '#builder' do
      it 'should wrap catalog method' do
        expect(@testobj.builder).to eq(@catalog.builder)
      end
    end

    describe '#catalog_json' do
      it 'should wrap catalog method' do
        expect(@testobj.catalog_json).to eq(@catalog.catalog_json)
      end
    end

    describe '#compilation_dir' do
      it 'should wrap catalog method' do
        expect(@testobj.compilation_dir).to eq(@catalog.compilation_dir)
      end
    end

    describe '#error_message' do
      it 'should wrap catalog method' do
        expect(@testobj.error_message).to eq(@catalog.error_message)
      end
    end

    describe '#puppet_version' do
      it 'should wrap catalog method' do
        expect(@testobj.puppet_version).to eq(@catalog.puppet_version)
      end
    end

    describe '#resource' do
      it 'should wrap catalog method' do
        param = { type: 'Package', title: 'ruby1.8-dev' }
        expect(@testobj.resource(param)).to eq(@catalog.resource(param))
      end
    end

    describe '#resources' do
      it 'should wrap catalog method' do
        expect(@testobj.resources).to eq(@catalog.resources)
      end
    end

    describe '#valid?' do
      it 'should wrap catalog method' do
        expect(@testobj.valid?).to eq(@catalog.valid?)
      end
    end
  end
end
