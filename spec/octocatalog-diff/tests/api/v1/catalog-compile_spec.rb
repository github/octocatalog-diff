# frozen_string_literal: true

require 'json'

require_relative '../../spec_helper'

require OctocatalogDiff::Spec.require_path('/api/v1/catalog-compile')

describe OctocatalogDiff::API::V1::CatalogCompile do
  describe '#catalog' do
    it 'should raise error if no options are passed' do
      expect { described_class.catalog }.to raise_error(ArgumentError)
    end

    it 'should raise error if non-hash options are passed' do
      expect { described_class.catalog([]) }.to raise_error(ArgumentError)
    end

    it 'should use the passed-in logger' do
      logger, _logger_str = OctocatalogDiff::Spec.setup_logger
      options = { logger: logger }
      expect(OctocatalogDiff::Util::Catalogs).to receive(:new) { |*args| raise args.last.object_id.to_s }
      expect { described_class.catalog(options) }.to raise_error(RuntimeError, logger.object_id.to_s)
    end

    it 'should construct a logger if one is not passed in' do
      expect(OctocatalogDiff::Util::Catalogs).to receive(:new) { |*args| raise args.last.class.to_s }
      expect { described_class.catalog({}) }.to raise_error(RuntimeError, 'Logger')
    end

    it 'should remove logger from options passed to catalogs class' do
      logger, _logger_str = OctocatalogDiff::Spec.setup_logger
      options = { foo: 'bar', logger: logger }
      expect(OctocatalogDiff::Util::Catalogs).to receive(:new) { |*args| raise args.first.to_json }
      raised_error = nil
      begin
        described_class.catalog(options)
      rescue RuntimeError => exc
        raised_error = exc.message
      end
      expect(raised_error).not_to be_nil
      raised_error_parsed = JSON.parse(raised_error)
      expect(raised_error_parsed['foo']).to eq('bar')
      expect(raised_error_parsed['logger']).to be_nil
    end

    it 'should call OctocatalogDiff::Util::Catalogs and return to-key' do
      obj = OpenStruct.new(catalogs: { to: 'to-catalog', from: 'from-catalog' })
      expect(OctocatalogDiff::Util::Catalogs).to receive(:new).and_return(obj)
      result = described_class.catalog({})
      expect(result).to eq('to-catalog')
    end
  end
end
