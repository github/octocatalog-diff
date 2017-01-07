# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_display_datatype_changes' do
    include_examples 'true/false option', 'display-datatype-changes', :display_datatype_changes
  end
end
