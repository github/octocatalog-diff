require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_header' do
    it 'should error when --header and --no-header are both specified' do
      expect { run_optparse(['--header', 'fizzbuzz', '--no-header']) }.to raise_error(ArgumentError)
    end

    it 'should error when --no-header and --header are both specified' do
      expect { run_optparse(['--no-header', '--header', 'fizzbuzz']) }.to raise_error(ArgumentError)
    end

    it 'should error when --default-header and --no-header are both specified' do
      expect { run_optparse(['--no-header', '--default-header']) }.to raise_error(ArgumentError)
    end

    it 'should error when --no-header and --default-header are both specified' do
      expect { run_optparse(['--default-header', '--no-header']) }.to raise_error(ArgumentError)
    end

    it 'should error when --header and --default-header are both specified' do
      expect { run_optparse(['--header', 'fizzbuzz', '--default-header']) }.to raise_error(ArgumentError)
    end

    it 'should error when --default-header and --header are both specified' do
      expect { run_optparse(['--default-header', '--header', 'fizzbuzz']) }.to raise_error(ArgumentError)
    end

    it 'should error when --header is provided with no argument' do
      expect { run_optparse(['--header']) }.to raise_error(OptionParser::MissingArgument)
    end

    it 'should set default header for --default-header' do
      result = run_optparse(['--default-header'])
      expect(result.key?(:no_header)).to eq(false)
      expect(result[:header]).to eq(:default)
    end

    it 'should set custom header for --header' do
      result = run_optparse(['--header', 'fizzbuzz'])
      expect(result.key?(:no_header)).to eq(false)
      expect(result[:header]).to eq('fizzbuzz')
    end

    it 'should set no header flag for --no-header' do
      result = run_optparse(['--no-header'])
      expect(result.key?(:no_header)).to eq(true)
      expect(result[:header]).to be(nil)
    end
  end
end
