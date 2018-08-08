# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_hostname' do
    it 'should set options[:node] when hostname is set with short form' do
      result = run_optparse(['-n', 'octonode.rspec'])
      expect(result.fetch(:node, 'key-not-defined')).to eq(%w[octonode.rspec])
    end

    it 'should set multiple nodes when passed a series of nodes' do
      result = run_optparse(['-n', 'octonode1.rspec,octonode2.rspec'])
      expect(result.fetch(:node, 'key-not-defined')).to eq(%w[octonode1.rspec octonode2.rspec])
    end
  end
end
