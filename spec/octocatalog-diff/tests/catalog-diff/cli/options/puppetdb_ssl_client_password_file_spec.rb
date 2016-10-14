require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_puppetdb_ssl_client_password_file' do
    it 'should handle --puppetdb-ssl-client-password-file with a valid file' do
      result = run_optparse(['--puppetdb-ssl-client-password-file', OctocatalogDiff::Spec.fixture_path('facts/facts.yaml')])
      expect(result[:puppetdb_ssl_client_password]).to eq(File.read(OctocatalogDiff::Spec.fixture_path('facts/facts.yaml')))
    end

    it 'should error when client password file is not found' do
      expect do
        run_optparse(['--puppetdb-ssl-client-password-file', OctocatalogDiff::Spec.fixture_path('caasdfadfs')])
      end.to raise_error(Errno::ENOENT)
    end
  end
end
