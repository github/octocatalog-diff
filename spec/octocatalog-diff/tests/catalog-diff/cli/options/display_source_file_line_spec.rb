# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_display_source_file_line' do
    include_examples 'true/false option', 'display-source', :display_source_file_line
  end
end
