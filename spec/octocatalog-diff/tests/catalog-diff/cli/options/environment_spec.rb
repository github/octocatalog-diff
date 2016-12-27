# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_environment' do
    it 'should handle --environment' do
      result = run_optparse(['--environment', 'fizzbuzz'])
      expect(result[:from_environment]).to eq('fizzbuzz')
      expect(result[:to_environment]).to eq('fizzbuzz')
    end

    it 'should handle --to-environment' do
      result = run_optparse(['--to-environment', 'fizzbuzz'])
      expect(result[:from_environment]).to be_nil
      expect(result[:to_environment]).to eq('fizzbuzz')
    end

    it 'should handle --from-environment' do
      result = run_optparse(['--from-environment', 'fizzbuzz'])
      expect(result[:from_environment]).to eq('fizzbuzz')
      expect(result[:to_environment]).to be_nil
    end

    it 'should handle --from-environment + --to-environment' do
      result = run_optparse(['--from-environment', 'fizzbuzz', '--to-environment', 'production'])
      expect(result[:from_environment]).to eq('fizzbuzz')
      expect(result[:to_environment]).to eq('production')
    end
  end
end
