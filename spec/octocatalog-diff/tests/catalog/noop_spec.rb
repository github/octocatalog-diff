# frozen_string_literal: true

require_relative '../spec_helper'
require OctocatalogDiff::Spec.require_path('/catalog')

describe OctocatalogDiff::Catalog::Noop do
  it 'should produce a valid but empty catalog' do
    testobj = OctocatalogDiff::Catalog.new(backend: :noop)
    expect(testobj.catalog).to eq('resources' => [])
    expect(testobj.catalog_json).to eq('{"resources":[]}')
    expect(testobj.error_message).to eq(nil)
    expect(testobj.resources).to eq([])
    expect(testobj.valid?).to eq(true)
  end
end
