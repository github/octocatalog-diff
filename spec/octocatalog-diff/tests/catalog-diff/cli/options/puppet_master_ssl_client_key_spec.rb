require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  let(:fixture) { OctocatalogDiff::Spec.fixture_path('ssl/generated/client.key') }
  let(:answer) { File.read(fixture) }

  describe '#opt_puppet_master_ssl_client_key' do
    it 'should handle --puppet-master-ssl-client-key with a valid file' do
      result = run_optparse(['--puppet-master-ssl-client-key', fixture])
      expect(result[:to_puppet_master_ssl_client_key]).to eq(answer)
      expect(result[:from_puppet_master_ssl_client_key]).to eq(answer)
    end

    it 'should error when ssl ca file is not found' do
      expect do
        run_optparse(['--puppet-master-ssl-client-key', OctocatalogDiff::Spec.fixture_path('ssl/generated/caasdfadfs.crt')])
      end.to raise_error(Errno::ENOENT)
    end

    it 'should handle --to-puppet-master-ssl-client-key with a valid file' do
      result = run_optparse(['--puppet-master-ssl-client-key', fixture])
      expect(result[:to_puppet_master_ssl_client_key]).to eq(answer)
    end

    it 'should handle --from-puppet-master-ssl-client-key with a valid file' do
      result = run_optparse(['--from-puppet-master-ssl-client-key', fixture])
      expect(result[:from_puppet_master_ssl_client_key]).to eq(answer)
    end
  end
end
