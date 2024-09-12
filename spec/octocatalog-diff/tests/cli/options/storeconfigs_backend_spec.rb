# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_storeconfigs_backend' do
    it 'should accept all valid arguments' do
      result = run_optparse(['--storeconfigs-backend', 'puppetdb,yaml,json'])
      expect(result[:validate_references]).to eq(%w(puppetdb yaml json))
    end
  end
end
