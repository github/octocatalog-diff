# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_puppet_master_ssl_ca' do
    it 'should handle --puppet-master-ssl-ca with a valid file' do
      result = run_optparse(['--puppet-master-ssl-ca', OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt')])
      expect(result[:to_puppet_master_ssl_ca]).to eq(OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'))
      expect(result[:from_puppet_master_ssl_ca]).to eq(OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'))
    end

    it 'should error when ssl ca file is not found' do
      expect do
        run_optparse(['--puppet-master-ssl-ca', OctocatalogDiff::Spec.fixture_path('ssl/generated/caasdfadfs.crt')])
      end.to raise_error(Errno::ENOENT)
    end

    it 'should handle --to-puppet-master-ssl-ca with a valid file' do
      result = run_optparse(['--puppet-master-ssl-ca', OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt')])
      expect(result[:to_puppet_master_ssl_ca]).to eq(OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'))
    end

    it 'should handle --from-puppet-master-ssl-ca with a valid file' do
      result = run_optparse(['--from-puppet-master-ssl-ca', OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt')])
      expect(result[:from_puppet_master_ssl_ca]).to eq(OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'))
    end
  end
end
