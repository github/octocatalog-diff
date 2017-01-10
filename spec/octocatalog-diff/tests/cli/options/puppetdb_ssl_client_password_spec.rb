# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_puppetdb_ssl_client_password' do
    it 'should handle --puppetdb-ssl-client-password with valid text' do
      result = run_optparse(['--puppetdb-ssl-client-password', 'secret'])
      expect(result[:puppetdb_ssl_client_password]).to eq('secret')
    end
  end
end
