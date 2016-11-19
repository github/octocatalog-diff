# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_hiera_config' do
    it 'should handle --hiera-config' do
      result = run_optparse(['--hiera-config', 'adflkadfs'])
      expect(result[:hiera_config]).to eq('adflkadfs')
      expect(result.key?(:no_hiera_config)).to eq(false)
    end

    it 'should handle --no-hiera-config' do
      result = run_optparse(['--no-hiera-config'])
      expect(result.key?(:hiera_config)).to eq(false)
      expect(result[:no_hiera_config]).to eq(true)
    end

    it 'should error when --hiera-config and --no-hiera-config are both specified' do
      expect { run_optparse(['--hiera-config', 'adflkadfs', '--no-hiera-config']) }.to raise_error(ArgumentError)
      expect { run_optparse(['--no-hiera-config', '--hiera-config', 'adflkadfs']) }.to raise_error(ArgumentError)
    end
  end
end
