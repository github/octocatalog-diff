require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_safe_to_delete_cached_master_dir' do
    it 'should be set to a directory path' do
      path = File.join(File.dirname(__FILE__), 'cached-master')
      result = run_optparse(['--safe-to-delete-cached-master-dir', path])
      expect(result[:safe_to_delete_cached_master_dir]).to eq(path)
    end

    it 'should be set to an absolute directory path' do
      path = File.join(File.dirname(__FILE__), '../../cli/options/cached-master')
      answer = File.join(File.dirname(__FILE__), 'cached-master')
      result = run_optparse(['--safe-to-delete-cached-master-dir', path])
      expect(result[:safe_to_delete_cached_master_dir]).to eq(answer)
    end
  end
end
