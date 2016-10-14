require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_pe_enc_ssl_ca' do
    it 'should handle --pe-enc-ssl-ca with a valid file' do
      result = run_optparse(['--pe-enc-ssl-ca', OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt')])
      expect(result[:pe_enc_ssl_ca]).to eq(OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'))
    end

    it 'should error when ssl ca file is not found' do
      expect do
        run_optparse(['--pe-enc-ssl-ca', OctocatalogDiff::Spec.fixture_path('ssl/generated/caasdfadfs.crt')])
      end.to raise_error(Errno::ENOENT)
    end
  end
end
