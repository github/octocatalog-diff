# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_puppet_master_update_catalog' do
    include_examples 'global true/false option', 'puppet-master-update-catalog', :puppet_master_update_catalog
  end
end
