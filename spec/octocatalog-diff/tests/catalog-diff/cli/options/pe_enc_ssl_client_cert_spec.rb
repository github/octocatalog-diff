require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_pe_enc_ssl_client_cert' do
    it 'should handle --pe-enc-ssl-client-cert with a valid file' do
      result = run_optparse(['--pe-enc-ssl-client-cert', OctocatalogDiff::Spec.fixture_path('ssl/generated/client.crt')])
      expect(result[:pe_enc_ssl_client_cert]).to eq(File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client.crt')))
    end

    it 'should error when client cert file is not found' do
      expect do
        run_optparse(['--pe-enc-ssl-client-cert', OctocatalogDiff::Spec.fixture_path('ssl/generated/caasdfadfs.crt')])
      end.to raise_error(Errno::ENOENT)
    end
  end
end
