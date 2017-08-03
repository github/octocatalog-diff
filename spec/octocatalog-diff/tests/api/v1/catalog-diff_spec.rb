# frozen_string_literal: true

require 'ostruct'

require_relative '../../spec_helper'

require OctocatalogDiff::Spec.require_path('/api/v1/catalog-diff')
require OctocatalogDiff::Spec.require_path('/cli/diffs')
require OctocatalogDiff::Spec.require_path('/util/catalogs')

describe OctocatalogDiff::API::V1::CatalogDiff do
  describe '#catalog_diff' do
    before(:each) do
      @from_catalog = OctocatalogDiff::Catalog.create(backend: :noop)
      @to_catalog = OctocatalogDiff::Catalog.create(backend: :noop)
    end

    it 'should raise error if no options are passed' do
      expect { described_class.catalog_diff }.to raise_error(ArgumentError)
    end

    it 'should raise error if non-hash options are passed' do
      expect { described_class.catalog_diff([]) }.to raise_error(ArgumentError)
    end

    context 'with :cached_master_dir undefined' do
      before(:each) do
        catalog_obj = OpenStruct.new(catalogs: { from: @from_catalog, to: @to_catalog })
        expect(OctocatalogDiff::Util::Catalogs).to receive(:new).and_return(catalog_obj)

        diffs_obj = double
        allow(diffs_obj).to receive(:diffs).and_return([['+', ''], ['-', '']])
        expect(OctocatalogDiff::Cli::Diffs).to receive(:new).and_return(diffs_obj)

        logger, @logger_str = OctocatalogDiff::Spec.setup_logger
        @result = described_class.catalog_diff(logger: logger, node: 'foo')
      end

      it 'should return the expected data structure' do
        expect(@result.diffs[0].raw).to eq(['+', ''])
        expect(@result.diffs[1].raw).to eq(['-', ''])
        expect(@result.from.raw).to eq(@from_catalog)
        expect(@result.to.raw).to eq(@to_catalog)
      end

      it 'should log the expected messages' do
        expect(@logger_str.string).to match(/Compiling catalogs for foo/)
        expect(@logger_str.string).to match(/Catalogs compiled for foo/)
        expect(@logger_str.string).to match(/Diffs computed for foo/)
        expect(@logger_str.string).not_to match(/No differences/)
        expect(@logger_str.string).not_to match(/Cached master catalog for foo/)
      end
    end

    context 'with :cached_master_dir defined' do
      before(:each) do
        expect(@from_catalog).to receive(:"compilation_dir=").with('foo')

        catalog_obj = OpenStruct.new(catalogs: { from: @from_catalog, to: @to_catalog })
        expect(OctocatalogDiff::Util::Catalogs).to receive(:new).and_return(catalog_obj)

        expect(OctocatalogDiff::CatalogUtil::CachedMasterDirectory).to receive(:save_catalog_in_cache_dir).and_return('yes')

        diffs_obj = double
        allow(diffs_obj).to receive(:diffs).and_return([])
        expect(OctocatalogDiff::Cli::Diffs).to receive(:new).and_return(diffs_obj)

        logger, @logger_str = OctocatalogDiff::Spec.setup_logger
        @result = described_class.catalog_diff(logger: logger, node: 'foo', cached_master_dir: 'foo', from_env: 'origin/master')
      end

      it 'should return the expected data structure' do
        expect(@result.diffs).to eq([])
        expect(@result.from.raw).to eq(@from_catalog)
        expect(@result.to.raw).to eq(@to_catalog)
      end

      it 'should log the expected messages' do
        expect(@logger_str.string).to match(/Compiling catalogs for foo/)
        expect(@logger_str.string).to match(/Catalogs compiled for foo/)
        expect(@logger_str.string).to match(/Diffs computed for foo/)
        expect(@logger_str.string).to match(/No differences/)
        expect(@logger_str.string).to match(/Cached master catalog for foo/)
      end
    end
  end
end
