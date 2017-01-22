# frozen_string_literal: true

require_relative 'integration_helper'

require 'json'

describe 'ENC override integration with no override' do
  before(:all) do
    @result = OctocatalogDiff::Integration.integration(
      spec_repo: 'enc-overrides',
      spec_fact_file: 'valid-facts.yaml',
      hiera_config: 'hiera.yaml',
      hiera_path: 'hieradata',
      argv: [
        '--enc',
        OctocatalogDiff::Spec.fixture_path('repos/enc-overrides/enc.sh')
      ]
    )
  end

  it 'should succeed' do
    expect(@result.exitcode).not_to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
    expect(@result.exitcode).to eq(0), "Runtime error: #{@result.logs}"
  end

  it 'should show no changes' do
    expect(@result.diffs).to eq([])
  end

  it 'should contain proper resources in to-catalog' do
    to_catalog = @result.to
    expect(to_catalog).to be_a_kind_of(OctocatalogDiff::API::V1::Catalog)

    file_one = to_catalog.resource(type: 'File', title: '/tmp/one')
    expect(file_one['parameters']['content']).to eq('one')

    file_two = to_catalog.resource(type: 'File', title: '/tmp/two')
    expect(file_two['parameters']['content']).to eq('one')
  end

  it 'should log proper messages' do
    expect(@result.log_messages).to include('DEBUG - Compiling catalogs for rspec-node.xyz.github.net')
    expect(@result.log_messages).to include('INFO - Catalogs compiled for rspec-node.xyz.github.net')
    expect(@result.log_messages).to include('INFO - No differences')
  end
end

describe 'ENC override integration with --enc-override' do
  before(:all) do
    @result = OctocatalogDiff::Integration.integration(
      spec_repo: 'enc-overrides',
      spec_fact_file: 'valid-facts.yaml',
      hiera_config: 'hiera.yaml',
      hiera_path: 'hieradata',
      argv: [
        '--no-parallel',
        '--enc',
        OctocatalogDiff::Spec.fixture_path('repos/enc-overrides/enc.sh'),
        '--enc-override', 'role=two'
      ]
    )
  end

  it 'should succeed' do
    expect(@result.exitcode).not_to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
    expect(@result.exitcode).to eq(0), "Runtime error: #{@result.logs}"
  end

  it 'should show no changes' do
    expect(@result.diffs).to eq([])
  end

  it 'should contain proper resources in to-catalog' do
    to_catalog = @result.to
    expect(to_catalog).to be_a_kind_of(OctocatalogDiff::API::V1::Catalog)

    file_one = to_catalog.resource(type: 'File', title: '/tmp/one')
    expect(file_one['parameters']['content']).to eq('two')

    file_two = to_catalog.resource(type: 'File', title: '/tmp/two')
    expect(file_two['parameters']['content']).to eq('two')
  end

  it 'should log proper messages' do
    expect(@result.log_messages).to include('DEBUG - ENC override: role = "two"')
  end
end

describe 'ENC override integration with --to-enc-override' do
  before(:all) do
    @result = OctocatalogDiff::Integration.integration(
      spec_repo: 'enc-overrides',
      spec_fact_file: 'valid-facts.yaml',
      hiera_config: 'hiera.yaml',
      hiera_path: 'hieradata',
      argv: [
        '--no-parallel',
        '--enc',
        OctocatalogDiff::Spec.fixture_path('repos/enc-overrides/enc.sh'),
        '--to-enc-override', 'role=two'
      ]
    )
  end

  it 'should succeed' do
    expect(@result.exitcode).not_to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
    expect(@result.exitcode).to eq(2), "Runtime error: #{@result.logs}"
  end

  it 'should show expected changes' do
    diffs = @result.diffs.map { |x| OctocatalogDiff::Spec.remove_file_and_line(x) }
    expect(diffs).to include(
      diff_type: '~',
      type: 'File',
      title: '/tmp/one',
      structure: %w(parameters content),
      old_value: 'one',
      new_value: 'two'
    )
    expect(diffs).to include(
      diff_type: '~',
      type: 'File',
      title: '/tmp/two',
      structure: %w(parameters content),
      old_value: 'one',
      new_value: 'two'
    )
  end

  it 'should log proper messages' do
    expect(@result.log_messages).to include('DEBUG - ENC override: role = "two"')
  end
end

describe 'ENC override integration with --from-enc-override' do
  before(:all) do
    @result = OctocatalogDiff::Integration.integration(
      spec_repo: 'enc-overrides',
      spec_fact_file: 'valid-facts.yaml',
      hiera_config: 'hiera.yaml',
      hiera_path: 'hieradata',
      argv: [
        '--no-parallel',
        '--enc',
        OctocatalogDiff::Spec.fixture_path('repos/enc-overrides/enc.sh'),
        '--from-enc-override', 'role=two'
      ]
    )
  end

  it 'should succeed' do
    expect(@result.exitcode).not_to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
    expect(@result.exitcode).to eq(2), "Runtime error: #{@result.logs}"
  end

  it 'should show expected changes' do
    diffs = @result.diffs.map { |x| OctocatalogDiff::Spec.remove_file_and_line(x) }
    expect(diffs).to include(
      diff_type: '~',
      type: 'File',
      title: '/tmp/one',
      structure: %w(parameters content),
      old_value: 'two',
      new_value: 'one'
    )
    expect(diffs).to include(
      diff_type: '~',
      type: 'File',
      title: '/tmp/two',
      structure: %w(parameters content),
      old_value: 'two',
      new_value: 'one'
    )
  end

  it 'should log proper messages' do
    expect(@result.log_messages).to include('DEBUG - ENC override: role = "two"')
  end
end

describe 'ENC override integration with catalog compilation only' do
  before(:all) do
    @result = OctocatalogDiff::Integration.integration(
      spec_repo: 'enc-overrides',
      spec_fact_file: 'valid-facts.yaml',
      hiera_config: 'hiera.yaml',
      hiera_path: 'hieradata',
      argv: [
        '--no-parallel',
        '--enc',
        OctocatalogDiff::Spec.fixture_path('repos/enc-overrides/enc.sh'),
        '--enc-override', 'role=two',
        '--catalog-only'
      ]
    )
  end

  it 'should succeed' do
    expect(@result.exitcode).not_to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
    expect(@result.exitcode).to eq(0), "Runtime error: #{@result.logs}"
  end

  it 'should show no changes' do
    expect(@result.to).to eq([])
  end

  it 'should log proper messages' do
    expect(@result.log_messages).to include('DEBUG - ENC override: role = "two"')
  end
end
