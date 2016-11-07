require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_debug_bootstrap' do
    it 'should handle --debug-bootstrap' do
      result = run_optparse(['--debug-bootstrap'])
      expect(result[:debug_bootstrap]).to eq(true)
    end
  end
end
