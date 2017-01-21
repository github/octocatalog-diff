# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_enc_override' do
    include_examples 'global array option', 'enc-override', :enc_override_in

    it 'should accept multiple ENC parameters of the same type' do
      args = ['--to-enc-override', 'foo=bar', '--to-enc-override', 'baz=buzz']
      result = run_optparse(args)
      expect(result[:to_enc_override_in]).to eq(['foo=bar', 'baz=buzz'])
    end
  end
end
