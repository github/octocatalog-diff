# frozen_string_literal: true

require_relative 'integration_helper'

OctocatalogDiff::Spec.require_path('/catalog')

describe 'preserve environments integration' do
  context 'without --preserve-environments set' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_fact_file: 'facts.yaml',
        spec_repo: 'preserve-environments',
        argv: [
          '-n', 'rspec-node.github.net'
        ]
      )
    end

    it 'should exit with error status' do
      expect(@result.exitcode).to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
    end

    it 'should raise OctocatalogDiff::CatalogDiff::Cli::Catalogs::CatalogError' do
      expect(@result.exception).to be_a_kind_of(OctocatalogDiff::CatalogDiff::Cli::Catalogs::CatalogError)
    end

    it 'should fail because ::bar could not be located' do
      expect(@result.exception.message).to match(/Could not find class ::bar for rspec-node.github.net/)
    end
  end

  context 'with --preserve-environments set' do
  end
end
