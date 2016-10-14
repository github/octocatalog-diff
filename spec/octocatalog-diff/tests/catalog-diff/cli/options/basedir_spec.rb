require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_basedir' do
    it 'should handle --basedir with existing path' do
      dirpath = OctocatalogDiff::Spec.fixture_path('facts')
      result = run_optparse(['--basedir', dirpath])
      expect(result[:basedir]).to eq(dirpath)
    end

    it 'should handle a relative path' do
      # This changes to the 'catalog-diff' directory, in which a 'cli'
      # directory exists. This file is in that 'cli' directory.
      Dir.chdir(File.expand_path('../..', File.dirname(__FILE__)))
      result = run_optparse(['--basedir', './cli/options'])
      expect(result[:basedir]).to eq(File.absolute_path(File.dirname(__FILE__)))
    end

    it 'should error for a non-existing path' do
      dirpath = OctocatalogDiff::Spec.fixture_path('asdfalkfjakfdjalskfjalkdfdf')
      expect do
        run_optparse(['--basedir', dirpath])
      end.to raise_error(Errno::ENOENT)
    end
  end
end
