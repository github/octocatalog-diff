# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_create_symlinks' do
    include_examples 'global array option', 'create-symlinks', :create_symlinks
  end
end
