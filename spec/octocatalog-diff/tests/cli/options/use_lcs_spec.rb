# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_use_lcs' do
    include_examples 'true/false option', 'use-lcs', :use_lcs
  end
end
