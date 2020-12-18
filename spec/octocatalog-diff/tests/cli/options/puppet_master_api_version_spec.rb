# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_puppet_master_api_version' do
    it 'should handle --puppet-master-api-version with API version 2 as a string' do
      result = run_optparse(['--puppet-master-api-version', '2'])
      expect(result[:to_puppet_master_api_version]).to eq(2)
      expect(result[:from_puppet_master_api_version]).to eq(2)
    end

    it 'should handle --puppet-master-api-version with API version 3 as a string' do
      result = run_optparse(['--puppet-master-api-version', '3'])
      expect(result[:to_puppet_master_api_version]).to eq(3)
      expect(result[:from_puppet_master_api_version]).to eq(3)
    end

    it 'should handle --puppet-master-api-version with API version 4 as a string' do
      result = run_optparse(['--puppet-master-api-version', '4'])
      expect(result[:to_puppet_master_api_version]).to eq(4)
      expect(result[:from_puppet_master_api_version]).to eq(4)
    end

    it 'should error on --puppet-master-api-version with unsupported API version' do
      expect { run_optparse(['--puppet-master-api-version', '99']) }.to raise_error(ArgumentError)
    end

    it 'should error on --puppet-master-api-version with malformed API version' do
      expect { run_optparse(['--puppet-master-api-version', 'sdfljkafs']) }.to raise_error(ArgumentError)
    end

    it 'should handle --to-puppet-master-api-version' do
      result = run_optparse(['--to-puppet-master-api-version', '3'])
      expect(result[:to_puppet_master_api_version]).to eq(3)
    end

    it 'should handle --from-puppet-master-api-version' do
      result = run_optparse(['--from-puppet-master-api-version', '3'])
      expect(result[:from_puppet_master_api_version]).to eq(3)
    end
  end
end
