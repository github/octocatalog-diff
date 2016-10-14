require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_output_file' do
    it 'should set absolute path for output to file' do
      target = File.absolute_path(__FILE__)
      result = run_optparse(['--output-file', target])
      expect(result[:output_file]).to eq(target)
    end

    it 'should convert relative path to absolute path' do
      # This changes to the 'catalog-diff' directory, in which a 'cli'
      # directory exists. This file is in that 'cli' directory.
      Dir.chdir(File.expand_path('../..', File.dirname(__FILE__)))
      target = File.absolute_path(__FILE__)
      result = run_optparse(['--output-file', './cli/options/output_file_spec.rb'])
      expect(result[:output_file]).to eq(target)
    end
  end
end
