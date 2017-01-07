# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_puppetdb_ssl_client_cert' do
    it 'should handle --puppetdb-ssl-client-cert with a valid file' do
      result = run_optparse(['--puppetdb-ssl-client-cert', OctocatalogDiff::Spec.fixture_path('ssl/generated/client.crt')])
      expect(result[:puppetdb_ssl_client_cert]).to eq(File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client.crt')))
    end

    it 'should error when client cert file is not found' do
      expect do
        run_optparse(['--puppetdb-ssl-client-cert', OctocatalogDiff::Spec.fixture_path('ssl/generated/caasdfadfs.crt')])
      end.to raise_error(Errno::ENOENT)
    end
  end
end
