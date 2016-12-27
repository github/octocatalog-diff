# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_preserve_environments' do
    include_examples 'true/false option', 'preserve-environments', :preserve_environments
  end
end
