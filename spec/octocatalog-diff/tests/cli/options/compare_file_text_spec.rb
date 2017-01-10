# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_compare_file_text' do
    include_examples 'true/false option', 'compare-file-text', :compare_file_text
  end
end
