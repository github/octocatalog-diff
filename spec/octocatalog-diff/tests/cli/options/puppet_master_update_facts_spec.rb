# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_puppet_master_update_facts' do
    include_examples 'global true/false option', 'puppet-master-update-facts', :puppet_master_update_facts
  end
end
