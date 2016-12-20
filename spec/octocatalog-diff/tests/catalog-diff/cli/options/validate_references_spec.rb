# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_validate_references' do
    it 'should accept an array of arguments' do
      result = run_optparse(['--validate-references', 'before', '--validate-references', 'require'])
      expect(result[:validate_references]).to eq(%w(before require))
    end

    it 'should accept comma separated arguments' do
      result = run_optparse(['--validate-references', 'before,require'])
      expect(result[:validate_references]).to eq(%w(before require))
    end

    it 'should accept all valid arguments' do
      result = run_optparse(['--validate-references', 'before,require,notify,subscribe'])
      expect(result[:validate_references]).to eq(%w(before require notify subscribe))
    end

    it 'should fail for an invalid argument' do
      expect { run_optparse(['--validate-references', 'chicken']) }.to raise_error(ArgumentError, /Invalid reference validation/)
    end
  end
end
