require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_include_tags' do
    include_examples 'true/false option', 'include-tags', :include_tags
  end
end
