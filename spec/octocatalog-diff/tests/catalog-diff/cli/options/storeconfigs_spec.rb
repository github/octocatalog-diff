# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_storeconfigs' do
    include_examples 'true/false option', 'storeconfigs', :storeconfigs
  end
end
