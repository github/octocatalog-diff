# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative 'options_helper'
require OctocatalogDiff::Spec.require_path('/catalog-diff/cli/options')
require OctocatalogDiff::Spec.require_path('/version')

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#option_globally_or_per_branch' do
    it 'should raise an error if an invalid data type is passed' do
      expect do
        OctocatalogDiff::CatalogDiff::Cli::Options.option_globally_or_per_branch(datatype: {})
      end.to raise_error(ArgumentError)
    end
  end

  describe '#parse_options' do
    it 'should return the correct version' do
      allow(described_class).to receive(:exit)
      regexp = Regexp.new("^octocatalog-diff #{OctocatalogDiff::Version::VERSION}\n$")
      expect { run_optparse(['--version']) }.to output(regexp).to_stdout
    end

    it 'should exit' do
      allow(described_class).to receive(:puts) # Suppresses output from appearing when running test
      expect { run_optparse(['--version']) }.to raise_error(SystemExit)
    end
  end
end
