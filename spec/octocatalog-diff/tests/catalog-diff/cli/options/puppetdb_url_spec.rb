require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_puppetdb_url' do
    it 'should handle --puppetdb-url with HTTP URL' do
      result = run_optparse(['--puppetdb-url', 'http://puppetdb.your-domain-here.com:8080'])
      expect(result[:puppetdb_url]).to eq('http://puppetdb.your-domain-here.com:8080')
    end

    it 'should handle --puppetdb-url with HTTPS URL' do
      result = run_optparse(['--puppetdb-url', 'https://puppetdb.your-domain-here.com:8081'])
      expect(result[:puppetdb_url]).to eq('https://puppetdb.your-domain-here.com:8081')
    end

    it 'should error when --puppetdb-url is not HTTP/HTTPS' do
      expect do
        run_optparse(['--puppetdb-url', 'afadflsafadlsadslfjkasdfljkasdflkadfjs'])
      end.to raise_error(ArgumentError, 'PuppetDB URL must be http or https')
    end
  end
end
