# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_command_line' do
    include_examples 'global array option', 'command-line', :command_line
  end
end
