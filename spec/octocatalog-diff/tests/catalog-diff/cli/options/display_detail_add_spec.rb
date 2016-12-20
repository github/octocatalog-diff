# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_display_detail_add' do
    include_examples 'true/false option', 'display-detail-add', :display_detail_add
  end
end
