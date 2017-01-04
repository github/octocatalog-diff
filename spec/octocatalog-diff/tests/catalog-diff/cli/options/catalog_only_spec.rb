# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_catalog_only' do
    include_examples 'true/false option', 'catalog-only', :catalog_only
  end
end
