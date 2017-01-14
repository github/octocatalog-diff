# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_ignore_equivalent_yaml_files' do
    it 'should accept comma delimited parameters for --filters' do
      result = run_optparse(['--filters', 'AbsentFile,YAML'])
      expect(result[:filters]).to eq(%w(AbsentFile YAML))
    end

    it 'should accept multiple parameters for --filters' do
      result = run_optparse(['--filters', 'AbsentFile', '--filters', 'YAML'])
      expect(result[:filters]).to eq(%w(AbsentFile YAML))
    end

    it 'should raise ArgumentError if invalid filter is specified' do
      expect do
        run_optparse(['--filters', 'AbsentFile,FizzBuzzDoesNotExist,YAML'])
      end.to raise_error(ArgumentError, 'The filter FizzBuzzDoesNotExist is not valid')
    end
  end
end
