# frozen_string_literal: true

require_relative 'integration_helper'
require 'json'

module OctocatalogDiff
  class Spec
    def self.reference_validation_catalog(role, validations)
      argv = ['--catalog-only', '-n', 'rspec-node.github.net', '--to-fact-override', "reference_validation_role=#{role}"]
      validations.each { |v| argv.concat ['--validate-references', v] }
      OctocatalogDiff::Integration.integration(
        hiera_config: 'hiera.yaml',
        spec_fact_file: 'facts.yaml',
        spec_repo: 'reference-validation',
        argv: argv
      )
    end
  end
end

describe 'validation of sample catalog' do
  before(:all) do
    @result = OctocatalogDiff::Spec.reference_validation_catalog('valid', [])
  end

  it 'should return the valid catalog' do
    expect(@result.exitcode).to eq(2)
  end

  it 'should not raise any exceptions' do
    expect(@result.exception).to be_nil, OctocatalogDiff::Integration.format_exception(@result)
  end

  it 'should contain representative resources' do
    json_obj = JSON.parse(@result.output)
    resources = json_obj['resources'] || json_obj['data']['resources']
    expect(resources).to be_a_kind_of(Array)
    expect(resources.select { |x| x['type'] == 'File' && x['title'] == '/tmp/test-main' }.size).not_to eq(0)
  end
end

describe 'validation of references' do
  context 'with valid catalog' do
    before(:all) do
      @result = OctocatalogDiff::Spec.reference_validation_catalog('all', %w(before require subscribe notify))
    end

    it 'should succeed' do
      expect(@result.exitcode).to eq(2)
    end

    it 'should not raise any exceptions' do
      expect(@result.exception).to be_nil, OctocatalogDiff::Integration.format_exception(@result)
    end
  end

  context 'with broken require' do
  end

  context 'with broken before' do
  end

  context 'with broken notify' do
  end

  context 'with broken subscribe' do
  end
end
