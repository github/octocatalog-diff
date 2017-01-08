# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_puppet_binary' do
    include_examples 'global string option', 'puppet-binary', :puppet_binary
  end
end
