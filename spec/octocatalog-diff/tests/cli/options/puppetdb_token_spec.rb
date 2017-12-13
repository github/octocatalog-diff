# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_puppetdb_token' do
    it 'should handle --puppetdb-token with a string arg' do
      result = run_optparse(['--puppetdb-token', 'foobar'])
      expect(result[:puppetdb_token]).to eq('foobar')
    end
  end
end
