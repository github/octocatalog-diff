# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_ignore_equivalent_yaml_files' do
    include_examples 'true/false option', 'ignore-equivalent-yaml-files', :ignore_equivalent_yaml_files
  end
end
