# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_retry_failed_catalog' do
    it 'should handle --retry-failed-catalog with integer' do
      result = run_optparse(['--retry-failed-catalog', '42'])
      expect(result[:retry_failed_catalog]).to eq(42)
    end

    it 'should error if --retry-failed-catalog is passed a non-integer' do
      expect { run_optparse(['--retry-failed-catalog', 'chicken']) }.to raise_error(OptionParser::InvalidArgument)
    end

    it 'should error if --retry-failed-catalog is not passed an argument' do
      expect { run_optparse(['--retry-failed-catalog']) }.to raise_error(OptionParser::MissingArgument)
    end
  end
end
