# frozen_string_literal: true

require_relative 'integration_helper'

OctocatalogDiff::Spec.require_path('/catalog')

describe 'pass environment variables integration' do
  let(:default_argv) do
    [
      '--catalog-only',
      '-n', 'rspec-node.github.net',
      '--bootstrapped-to-dir', OctocatalogDiff::Spec.fixture_path('repos/environment-variables')
    ]
  end

  it 'should generate catalog without environment variable passed through' do
    ENV['FOO'] = 'this shall not pass'
    result = OctocatalogDiff::Integration.integration(
      spec_fact_file: 'facts.yaml',
      argv: default_argv
    )
    expect(result[:exitcode]).not_to eq(-1), OctocatalogDiff::Integration.format_exception(result)
    catalog = OctocatalogDiff::Catalog.new(json: result[:output])
    expect(catalog).to be_a_kind_of(OctocatalogDiff::Catalog)
    expect(catalog.valid?).to eq(true), catalog.error_message
    expect(catalog.resource(type: 'File', title: '/tmp/foo')['parameters']).to eq('content' => 'Foo is undefined')
  end

  it 'should generate catalog with environment variable passed through' do
    ENV['FOO'] = 'this shall pass'
    result = OctocatalogDiff::Integration.integration(
      spec_fact_file: 'facts.yaml',
      argv: default_argv + ['--pass-env-vars', 'FOO']
    )
    expect(result[:exitcode]).not_to eq(-1), OctocatalogDiff::Integration.format_exception(result)
    catalog = OctocatalogDiff::Catalog.new(json: result[:output])
    expect(catalog).to be_a_kind_of(OctocatalogDiff::Catalog)
    expect(catalog.valid?).to eq(true), catalog.error_message
    expect(catalog.resource(type: 'File', title: '/tmp/foo')['parameters']).to eq('content' => 'Foo is this shall pass')
  end
end
