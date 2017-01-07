# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_bootstrap_then_exit' do
    it 'should handle --bootstrap-then-exit' do
      result = run_optparse(['--bootstrap-then-exit'])
      expect(result[:bootstrap_then_exit]).to eq(true)
    end
  end
end
