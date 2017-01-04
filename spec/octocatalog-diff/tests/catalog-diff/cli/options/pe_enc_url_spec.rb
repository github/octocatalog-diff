# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_pe_enc_url' do
    it 'should handle --pe-enc-url with HTTPS URL' do
      result = run_optparse(['--pe-enc-url', 'https://pe-enc.your-domain-here.com:4433/classifier-api'])
      expect(result[:pe_enc_url]).to eq('https://pe-enc.your-domain-here.com:4433/classifier-api')
    end

    it 'should error when --pe-enc-url is not HTTPS' do
      expect do
        run_optparse(['--pe-enc-url', 'http://pe-enc.your-domain-here.com:4433/classifier-api'])
      end.to raise_error(ArgumentError, 'PE ENC URL must be https')
    end
  end
end
