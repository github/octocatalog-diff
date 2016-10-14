require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_puppet_master_cache_branch' do
    it 'should handle --puppet-master-api-version with a string arg' do
      result = run_optparse(['--master-cache-branch', 'foobar'])
      expect(result[:master_cache_branch]).to eq('foobar')
    end
  end
end
