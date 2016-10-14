require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_puppetdb_ssl_client_key' do
    it 'should handle --puppetdb-ssl-client-key with a valid file' do
      result = run_optparse(['--puppetdb-ssl-client-key', OctocatalogDiff::Spec.fixture_path('ssl/generated/client.key')])
      expect(result[:puppetdb_ssl_client_key]).to eq(File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client.key')))
    end

    it 'should error when client key file is not found' do
      expect do
        run_optparse(['--puppetdb-ssl-client-key', OctocatalogDiff::Spec.fixture_path('ssl/generated/caasdfadfs.key')])
      end.to raise_error(Errno::ENOENT)
    end
  end
end
