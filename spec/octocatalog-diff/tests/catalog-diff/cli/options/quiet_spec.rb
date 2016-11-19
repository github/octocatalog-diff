# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_quiet' do
    include_examples 'true/false option', 'quiet', :quiet
  end
end
