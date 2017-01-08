# frozen_string_literal: true

require 'json'

require_relative '../../spec_helper'

require OctocatalogDiff::Spec.require_path('/api/v1/common')

describe OctocatalogDiff::API::V1::Common do
  describe '#logger_from_options' do
    it 'should use the passed-in logger' do
      logger, _logger_str = OctocatalogDiff::Spec.setup_logger
      options = { logger: logger, foo: 'bar' }
      result_opts, result_logger = described_class.logger_from_options(options)
      expect(result_logger).to eq(logger)
      expect(result_opts).to eq(foo: 'bar', logger: nil)
    end

    it 'should construct a logger if one is not passed in' do
      result_opts, result_logger = described_class.logger_from_options(foo: 'bar')
      expect(result_logger).to be_a_kind_of(Logger)
      expect(result_opts).to eq(foo: 'bar', logger: nil)
    end

    it 'should remove logger from options passed to catalogs class' do
      logger, _logger_str = OctocatalogDiff::Spec.setup_logger
      options = { foo: 'bar', logger: logger }
      result_opts, result_logger = described_class.logger_from_options(options)
      expect(result_opts[:foo]).to eq('bar')
      expect(result_opts[:logger]).to be_nil
      expect(result_logger).to eq(logger)
    end
  end
end
