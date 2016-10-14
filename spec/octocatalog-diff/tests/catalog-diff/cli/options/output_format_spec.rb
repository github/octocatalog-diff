require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_output_format' do
    valid = %w(text json)
    valid.each do |fmt|
      it "should set output format to #{fmt}" do
        result = run_optparse(['--output-format', fmt])
        expect(result[:format]).to eq(fmt.to_sym)
      end
    end

    it 'should error when unrecognized option is supplied' do
      expect { run_optparse(['--output-format', 'aldkfalkdf']) }.to raise_error(ArgumentError)
    end
  end
end
