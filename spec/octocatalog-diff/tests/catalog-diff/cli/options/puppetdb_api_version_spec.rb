require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_puppetdb_api_version' do
    it 'should handle --puppetdb-api-version with API version 3' do
      result = run_optparse(['--puppetdb-api-version', '3'])
      expect(result[:puppetdb_api_version]).to eq(3)
    end

    it 'should handle --puppetdb-api-version with API version 4' do
      result = run_optparse(['--puppetdb-api-version', '4'])
      expect(result[:puppetdb_api_version]).to eq(4)
    end

    it 'should fail if --puppetdb-api-version is unsupported' do
      expect { run_optparse(['--puppetdb-api-version', '9000']) }.to raise_error(ArgumentError)
    end
  end
end
