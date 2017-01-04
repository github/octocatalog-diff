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
  end
end
