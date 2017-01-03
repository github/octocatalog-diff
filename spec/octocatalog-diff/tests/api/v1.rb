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
end
