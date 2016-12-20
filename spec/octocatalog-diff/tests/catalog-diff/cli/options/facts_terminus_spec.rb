# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_facts_terminus' do
    valid = %w(yaml facter)
    valid.each do |fmt|
      it "should set facts terminus to #{fmt}" do
        result = run_optparse(['--facts-terminus', fmt])
        expect(result[:facts_terminus]).to eq(fmt)
      end
    end

    it 'should error when unrecognized option is supplied' do
      expect { run_optparse(['--facts-terminus', 'aldkfalkdf']) }.to raise_error(ArgumentError)
    end
  end
end
