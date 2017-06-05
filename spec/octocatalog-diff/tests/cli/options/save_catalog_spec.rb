# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_save_catalog' do
    it 'should raise error if catalog parent directory does not exist' do
      args = [
        '--to-save-catalog',
        OctocatalogDiff::Spec.fixture_path('non/exists/catalog.json')
      ]
      expect { run_optparse(args) }.to raise_error(Errno::ENOENT, /parent directory does not exist/)
    end

    it 'should raise error if catalog exists but is not a file' do
      args = [
        '--to-save-catalog',
        OctocatalogDiff::Spec.fixture_path('repos/default')
      ]
      expect { run_optparse(args) }.to raise_error(ArgumentError, /Cannot overwrite/)
    end

    it 'should not raise error if catalog file already exists' do
      args = [
        '--to-save-catalog',
        OctocatalogDiff::Spec.fixture_path('catalogs/catalog-1.json')
      ]
      result = run_optparse(args)
      expect(result[:to_save_catalog]).to eq(OctocatalogDiff::Spec.fixture_path('catalogs/catalog-1.json'))
    end

    it 'should not raise error if catalog file does not exist' do
      args = [
        '--to-save-catalog',
        OctocatalogDiff::Spec.fixture_path('catalogs/brand-new-catalog-1.json')
      ]
      result = run_optparse(args)
      expect(result[:to_save_catalog]).to eq(OctocatalogDiff::Spec.fixture_path('catalogs/brand-new-catalog-1.json'))
    end

    it 'should raise error if --to-save-catalog == --from-save-catalog' do
      args = [
        '--to-save-catalog',
        OctocatalogDiff::Spec.fixture_path('catalogs/brand-new-catalog-1.json'),
        '--from-save-catalog',
        OctocatalogDiff::Spec.fixture_path('catalogs/brand-new-catalog-1.json')
      ]
      expect { run_optparse(args) }.to raise_error(ArgumentError, /Cannot use the same file for/)
    end

    it 'should not raise error if --to-save-catalog and --from-save-catalog are both nil' do
      args = []
      result = run_optparse(args)
      expect(result[:to_save_catalog]).to be_nil
      expect(result[:from_save_catalog]).to be_nil
    end

    it 'should set option correctly' do
      args = [
        '--to-save-catalog',
        OctocatalogDiff::Spec.fixture_path('catalogs/brand-new-catalog-1.json'),
        '--from-save-catalog',
        OctocatalogDiff::Spec.fixture_path('catalogs/brand-new-catalog-2.json')
      ]
      result = run_optparse(args)
      expect(result[:to_save_catalog]).to eq(OctocatalogDiff::Spec.fixture_path('catalogs/brand-new-catalog-1.json'))
      expect(result[:from_save_catalog]).to eq(OctocatalogDiff::Spec.fixture_path('catalogs/brand-new-catalog-2.json'))
    end
  end
end
