# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_puppetdb_ssl_crl' do
    it 'should handle --puppetdb-ssl-crl with a valid file' do
      result = run_optparse(['--puppetdb-ssl-crl', OctocatalogDiff::Spec.fixture_path('ssl/generated/crl.pem')])
      expect(result[:puppetdb_ssl_crl]).to eq(OctocatalogDiff::Spec.fixture_path('ssl/generated/crl.pem'))
    end

    it 'should error when ssl crl file is not found' do
      expect do
        run_optparse(['--puppetdb-ssl-crl', OctocatalogDiff::Spec.fixture_path('ssl/generated/caasdfadfs.crt')])
      end.to raise_error(Errno::ENOENT)
    end
  end
end
