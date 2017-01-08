# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_color' do
    it 'should set colors off for output to file' do
      target = File.absolute_path(__FILE__)
      result = run_optparse(['--output-file', target])
      expect(result[:colors]).to eq(false)
    end

    include_examples 'true/false option', 'color', :colors
  end
end
