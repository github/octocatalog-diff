# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_ignore_equivalent_yaml_files' do
    it 'should accept comma delimited parameters for --filters' do
      result = run_optparse(['--filters', 'fizzbuzz,barbuzz'])
      expect(result[:filters]).to eq(%w(fizzbuzz barbuzz))
    end

    it 'should accept multiple parameters for --filters' do
      result = run_optparse(['--filters', 'fizzbuzz', '--filters', 'barbuzz'])
      expect(result[:filters]).to eq(%w(fizzbuzz barbuzz))
    end
  end
end
