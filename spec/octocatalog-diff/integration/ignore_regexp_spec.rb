# frozen_string_literal: true

require_relative 'integration_helper'

describe 'ignore regexp integration' do
  before(:all) do
    @result = OctocatalogDiff::API::V1.catalog_diff(
      to_catalog: OctocatalogDiff::Spec.fixture_path('catalogs/default-catalog-changed.json'),
      from_catalog: OctocatalogDiff::Spec.fixture_path('catalogs/default-catalog-v4.json'),
      ignore: [
        {
          type: Regexp.new('\ASsh_authorized_key\z'),
          attr: Regexp.new("\\Aparameters\f(foo|bar)\\z")
        }
      ]
    )
  end

  it 'should succeed' do
    expect(@result.diffs).to be_a_kind_of(Array)
  end

  it 'should contain a non-ignored diff in another type' do
    lookup = { diff_type: '+', type: 'Group', title: 'bill' }
    expect(OctocatalogDiff::Spec.diff_match?(@result.diffs, lookup)).to eq(true), @result.diffs.inspect
  end

  it 'should contain a non-ignored removal in the same type' do
    lookup = { type: 'Ssh_authorized_key', title: 'root@6def27049c06f48eea8b8f37329f40799d07dc84' }
    expect(OctocatalogDiff::Spec.diff_match?(@result.diffs, lookup)).to eq(true), @result.diffs.inspect
  end

  it 'should contain a non-ignored diff in the same type' do
    lookup = { type: 'Ssh_authorized_key', title: 'bob@local', structure: %w[parameters type] }
    expect(OctocatalogDiff::Spec.diff_match?(@result.diffs, lookup)).to eq(true), @result.diffs.inspect
  end

  it 'should not contain an ignored diff in the same type' do
    lookup = { type: 'Ssh_authorized_key', title: 'bob@local', structure: %w[parameters foo] }
    expect(OctocatalogDiff::Spec.diff_match?(@result.diffs, lookup)).to eq(false), @result.diffs.inspect
  end
end
