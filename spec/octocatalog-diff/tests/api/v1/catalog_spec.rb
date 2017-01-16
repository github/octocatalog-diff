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
        expect(@testobj.builder).to be_a_kind_of(String)
      end
    end

    describe '#to_json' do
      it 'should wrap catalog method' do
        expect(@testobj.to_json).to eq(@catalog.catalog_json)
        expect(@testobj.to_json).to be_a_kind_of(String)
      end
    end

    describe '#compilation_dir' do
      it 'should wrap catalog method if nil' do
        expect(@testobj.compilation_dir).to eq(@catalog.compilation_dir)
        expect(@testobj.compilation_dir).to be_nil
      end

      it 'should wrap catalog method if not nil' do
        expect(@catalog).to receive(:compilation_dir).and_return('foo')
        expect(@testobj.compilation_dir).to eq('foo')
      end
    end

    describe '#error_message' do
      it 'should wrap catalog method if nil' do
        expect(@testobj.error_message).to eq(@catalog.error_message)
        expect(@testobj.error_message).to be_nil
      end

      it 'should wrap catalog method if not nil' do
        expect(@catalog).to receive(:error_message).and_return('foo')
        expect(@testobj.error_message).to eq('foo')
      end
    end

    describe '#puppet_version' do
      it 'should wrap catalog method if nil' do
        expect(@testobj.puppet_version).to eq(@catalog.puppet_version)
        expect(@testobj.puppet_version).to be_nil
      end

      it 'should wrap catalog method if not nil' do
        expect(@catalog).to receive(:puppet_version).and_return('foo')
        expect(@testobj.puppet_version).to eq('foo')
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
        expect(@testobj.resources).to be_a_kind_of(Array)
      end
    end

    describe '#valid?' do
      it 'should wrap catalog method' do
        expect(@testobj.valid?).to eq(@catalog.valid?)
        expect(@testobj.valid?).to be_a_kind_of(TrueClass)
      end
    end

    describe '#to_h' do
      it 'should wrap catalog method' do
        expect(@testobj.to_h).to eq(@catalog.catalog)
        expect(@testobj.to_h).to be_a_kind_of(Hash)
      end
    end
  end
end
