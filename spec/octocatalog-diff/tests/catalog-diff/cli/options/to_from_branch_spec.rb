# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_to_from_branch' do
    it 'should set options[:from_env]' do
      result = run_optparse(['-f', 'origin/rspec-from-branch'])
      expect(result.fetch(:from_env, 'key-not-defined')).to eq('origin/rspec-from-branch')
    end

    it 'should set options[:to_env]' do
      result = run_optparse(['-t', 'origin/rspec-to-branch'])
      expect(result.fetch(:to_env, 'key-not-defined')).to eq('origin/rspec-to-branch')
    end
  end
end
