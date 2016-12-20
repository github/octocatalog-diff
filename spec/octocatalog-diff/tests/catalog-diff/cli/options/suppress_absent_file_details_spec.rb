# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_suppress_absent_file_details' do
    include_examples 'true/false option', 'suppress-absent-file-details', :suppress_absent_file_details
  end
end
