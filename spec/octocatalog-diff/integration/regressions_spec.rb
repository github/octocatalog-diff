# Miscellaneous regressions
#
# - file resource with no parameters
#   Inspired by https://github.com/github/octocatalog-diff/pull/122

# frozen_string_literal: true

require_relative 'integration_helper'

describe 'miscellaneous regressions' do
  before(:all) do
    @result = OctocatalogDiff::Integration.integration(
      spec_repo: 'regressions',
      spec_fact_file: 'facts.yaml',
      argv: [
        '--hiera-config', 'environments/production/hiera.yaml',
        '--hiera-path-strip', '/var/lib/puppet'
      ]
    )
  end

  it 'should run without an error' do
    expect(@result[:exitcode]).not_to eq(-1), "Internal error: #{OctocatalogDiff::Integration.format_exception(@result)}"
    expect(@result[:exitcode]).to eq(0), "Runtime error: #{@result[:logs]}"
    expect(@result[:diffs].size).to eq(0), @result[:diffs].map(&:inspect).join("\n")
  end
end

describe 'resource with Fixnum parameters added' do
  before(:all) do
    @result = OctocatalogDiff::Integration.integration(
      from_catalog: OctocatalogDiff::Spec.fixture_path('catalogs/regression-fixnum-1.json'),
      to_catalog: OctocatalogDiff::Spec.fixture_path('catalogs/regression-fixnum-2.json')
    )
  end

  it 'should run without an error' do
    expect(@result[:exitcode]).not_to eq(-1), "Internal error: #{OctocatalogDiff::Integration.format_exception(@result)}"
    expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
    expect(@result[:diffs].size).to eq(1), @result[:diffs].map(&:inspect).join("\n")
  end
end
