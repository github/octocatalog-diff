# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_puppet_master' do
    include_examples 'global string option', 'puppet-master', :puppet_master
  end
end
