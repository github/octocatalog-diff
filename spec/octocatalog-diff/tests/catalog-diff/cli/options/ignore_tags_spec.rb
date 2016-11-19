# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_ignore_tags' do
    it 'should error when --ignore-tags and --no-ignore-tags are both specified' do
      expect { run_optparse(['--ignore-tags', 'fizzbuzz', '--no-ignore-tags']) }.to raise_error(ArgumentError)
    end

    it 'should error when --no-ignore-tags and --ignore-tags are both specified' do
      expect { run_optparse(['--no-ignore-tags', '--ignore-tags', 'fizzbuzz']) }.to raise_error(ArgumentError)
    end

    it 'should error when --ignore-tags is provided with no argument' do
      expect { run_optparse(['--ignore-tags']) }.to raise_error(OptionParser::MissingArgument)
    end

    it 'should set custom parameter for --ignore-tags' do
      result = run_optparse(['--ignore-tags', 'fizzbuzz'])
      expect(result.key?(:no_ignore_tags)).to eq(false)
      expect(result[:ignore_tags]).to eq(['fizzbuzz'])
    end

    it 'should accept comma delimited parameters for --ignore-tags' do
      result = run_optparse(['--ignore-tags', 'fizzbuzz,barbuzz'])
      expect(result.key?(:no_ignore_tags)).to eq(false)
      expect(result[:ignore_tags]).to eq(%w(fizzbuzz barbuzz))
    end

    it 'should accept multiple parameters for --ignore-tags' do
      result = run_optparse(['--ignore-tags', 'fizzbuzz', '--ignore-tags', 'barbuzz'])
      expect(result.key?(:no_ignore_tags)).to eq(false)
      expect(result[:ignore_tags]).to eq(%w(fizzbuzz barbuzz))
    end

    it 'should set no magic ignore param flag for --no-ignore-tags' do
      result = run_optparse(['--no-ignore-tags'])
      expect(result.key?(:no_ignore_tags)).to eq(true)
      expect(result[:ignore_tags]).to be(nil)
    end
  end
end
