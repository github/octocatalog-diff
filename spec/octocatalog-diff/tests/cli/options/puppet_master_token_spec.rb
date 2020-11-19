# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_puppet_master_token' do
    include_examples 'global string option',
                     'puppet-master-token',
                     :puppet_master_token
  end
end
