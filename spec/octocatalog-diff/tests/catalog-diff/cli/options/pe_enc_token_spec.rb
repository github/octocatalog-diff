require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_pe_enc_token' do
    it 'should handle --pe-enc-token with a string arg' do
      result = run_optparse(['--pe-enc-token', 'foobar'])
      expect(result[:pe_enc_token]).to eq('foobar')
    end
  end
end
