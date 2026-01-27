# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_fact_override' do
    include_examples 'global array option', 'fact-override', :fact_override_in

    it 'should accept multiple facts of the same type' do
      args = ['--to-fact-override', 'foo=bar', '--to-fact-override', 'baz=buzz']
      result = run_optparse(args)
      expect(result[:to_fact_override_in]).to eq(['foo=bar', 'baz=buzz'])
    end

    it 'should not split JSON overrides containing commas' do
      args = ['--fact-override', 'json_list=(json)["a","b","c"]']
      result = run_optparse(args)
      expect(result[:to_fact_override_in]).to eq(['json_list=(json)["a","b","c"]'])
      expect(result[:from_fact_override_in]).to eq(['json_list=(json)["a","b","c"]'])
    end

    it 'should accept a comma-separated list of overrides' do
      args = ['--fact-override', 'foo=bar,baz=buzz']
      result = run_optparse(args)
      expect(result[:to_fact_override_in]).to eq(['foo=bar', 'baz=buzz'])
      expect(result[:from_fact_override_in]).to eq(['foo=bar', 'baz=buzz'])
    end

    it 'should split comma-separated overrides but not split commas inside JSON' do
      args = ['--fact-override', 'foo=bar,json_list=(json)["a","b"],baz=buzz']
      result = run_optparse(args)
      expect(result[:to_fact_override_in]).to eq(['foo=bar', 'json_list=(json)["a","b"]', 'baz=buzz'])
      expect(result[:from_fact_override_in]).to eq(['foo=bar', 'json_list=(json)["a","b"]', 'baz=buzz'])
    end
  end
end
