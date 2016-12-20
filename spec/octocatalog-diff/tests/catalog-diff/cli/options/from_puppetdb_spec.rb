# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_from_puppetdb' do
    include_examples 'true/false option', 'from-puppetdb', :from_puppetdb
  end
end
