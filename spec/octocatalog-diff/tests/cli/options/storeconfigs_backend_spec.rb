# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_storeconfigs_backend' do
    it 'should accept all valid arguments' do
      result = run_optparse(['--storeconfigs-backend', 'puppetdb'])
      expect(result[:storeconfigs_backend]).to eq('puppetdb')
    end
  end
end
