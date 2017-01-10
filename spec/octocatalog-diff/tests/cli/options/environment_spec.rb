# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_environment' do
    include_examples 'global string option', 'environment', :environment
  end
end
