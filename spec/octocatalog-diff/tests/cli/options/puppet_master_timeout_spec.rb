# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_puppet_master_timeout' do
    it 'should handle --puppet-master-timeout with timeout as a string' do
      result = run_optparse(['--puppet-master-timeout', '20'])
      expect(result[:to_puppet_master_timeout]).to eq(20)
      expect(result[:from_puppet_master_timeout]).to eq(20)
    end

    it 'should raise error if --puppet-master-timeout == 0' do
      expect do
        run_optparse(['--puppet-master-timeout', '0'])
      end.to raise_error(ArgumentError, 'Specify timeout as a integer greater than 0')
    end

    it 'should raise error if --puppet-master-timeout evaluates to 0' do
      expect do
        run_optparse(['--puppet-master-timeout', 'chickens'])
      end.to raise_error(ArgumentError, 'Specify timeout as a integer greater than 0')
    end

    it 'should handle --to-puppet-master-timeout' do
      result = run_optparse(['--to-puppet-master-timeout', '3'])
      expect(result[:to_puppet_master_timeout]).to eq(3)
    end

    it 'should handle --from-puppet-master-timeout' do
      result = run_optparse(['--from-puppet-master-timeout', '3'])
      expect(result[:from_puppet_master_timeout]).to eq(3)
    end
  end
end
