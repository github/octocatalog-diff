require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_bootstrap_current' do
    it 'should handle --bootstrap-current' do
      result = run_optparse(['--bootstrap-current'])
      expect(result[:bootstrap_current]).to eq(true)
    end
  end
end
