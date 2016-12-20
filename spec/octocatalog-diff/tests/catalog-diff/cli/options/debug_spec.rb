# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_debug' do
    include_examples 'true/false option', 'debug', :debug
  end
end
