# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_fact_dir' do
    let(:fact_dir) { OctocatalogDiff::Spec.fixture_path('facts') }

    it 'should set fact_file_dir for to/from when provided' do
      result = run_optparse(['--fact-dir', fact_dir])
      expect(result[:to_fact_file_dir]).to eq(fact_dir)
      expect(result[:from_fact_file_dir]).to eq(fact_dir)
    end

    it 'should allow branch-specific values' do
      result = run_optparse(['--to-fact-dir', fact_dir])
      expect(result[:to_fact_file_dir]).to eq(fact_dir)
      expect(result.key?(:from_fact_file_dir)).to be(false)
    end

    it 'should resolve relative paths against basedir' do
      result = run_optparse(['--fact-dir', 'spec/octocatalog-diff/fixtures/facts'], basedir: Dir.pwd)
      expect(result[:to_fact_file_dir]).to eq(fact_dir)
      expect(result[:from_fact_file_dir]).to eq(fact_dir)
    end

    it 'should throw error if --puppetdb-url is also provided' do
      expect do
        run_optparse(['--fact-dir', fact_dir, '--puppetdb-url', 'http://localhost:8080'])
      end.to raise_error(ArgumentError)
    end
  end
end
