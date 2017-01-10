# frozen_string_literal: true

require_relative '../spec_helper'

require OctocatalogDiff::Spec.require_path('/api/v1')

describe OctocatalogDiff::API::V1 do
  describe '#catalog' do
    it 'should call CatalogCompile.catalog with passed-in arguments' do
      args = { foo: 'bar' }
      expect(OctocatalogDiff::API::V1::CatalogCompile).to receive(:catalog).with(args)
      expect { described_class.catalog(args) }.not_to raise_error
    end
  end

  describe '#catalog_diff' do
    it 'should call CatalogDiff.catalog_diff with passed-in arguments' do
      args = { foo: 'bar' }
      expect(OctocatalogDiff::API::V1::CatalogDiff).to receive(:catalog_diff).with(args)
      expect { described_class.catalog_diff(args) }.not_to raise_error
    end
  end

  describe '#config' do
    it 'should call CatalogDiff.config with passed-in arguments' do
      args = { foo: 'bar' }
      expect(OctocatalogDiff::API::V1::Config).to receive(:config).with(args)
      expect { described_class.config(args) }.not_to raise_error
    end
  end
end
