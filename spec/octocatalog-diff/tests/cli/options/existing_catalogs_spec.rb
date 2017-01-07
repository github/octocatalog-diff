# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_existing_catalogs' do
    before(:all) do
      @cat = OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog.json')
      @from_result = run_optparse(['--from-catalog', @cat])
      @to_result = run_optparse(['--to-catalog', @cat])
    end

    it 'should set options[:from_catalog]' do
      expect(@from_result.fetch(:from_catalog, 'key-not-defined')).to eq(@cat)
    end

    it 'should set options[:to_catalog]' do
      expect(@to_result.fetch(:to_catalog, 'key-not-defined')).to eq(@cat)
    end

    it 'should parse the node name out of a catalog' do
      expect(@from_result[:node]).to eq('my.rspec.node')
    end

    it 'should error if an invalid catalog file is supplied' do
      expect do
        cat = OctocatalogDiff::Spec.fixture_path('this-file-does-not-exist.json')
        run_optparse(['--from-catalog', cat])
      end.to raise_error(Errno::ENOENT)
    end
  end
end
