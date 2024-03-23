# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_compare_file_text' do
    it 'should set options[:compare_file_text] to true when --compare-file-text is set with no extra argument' do
      result = run_optparse(['--compare-file-text'])
      expect(result[:compare_file_text]).to eq(true)
    end

    it 'should set options[:compare_file_text] to :force when --compare-file-text is set to force' do
      result = run_optparse(['--compare-file-text=force'])
      expect(result[:compare_file_text]).to eq(:force)
    end

    it 'should set options[:compare_file_text] to :soft when --compare-file-text is set to soft' do
      result = run_optparse(['--compare-file-text=soft'])
      expect(result[:compare_file_text]).to eq(:soft)
    end

    it 'should set options[:compare_file_text] to false when --no-compare-file-text is set' do
      result = run_optparse(['--no-compare-file-text'])
      expect(result[:compare_file_text]).to eq(false)
    end

    it 'should raise if an unnecessary argument is passed to --compare-file-text' do
      expect { run_optparse(['--no-compare-file-text=blah']) }.to raise_error(OptionParser::NeedlessArgument)
    end

    it 'should raise if an argument is passed to --no-compare-file-text' do
      expect { run_optparse(['--no-compare-file-text=force']) }.to raise_error(OptionParser::NeedlessArgument)
    end
  end
end
