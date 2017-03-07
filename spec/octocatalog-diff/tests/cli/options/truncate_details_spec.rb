# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_truncate_details' do
    include_examples 'true/false option', 'truncate-details', :truncate_details
  end
end
