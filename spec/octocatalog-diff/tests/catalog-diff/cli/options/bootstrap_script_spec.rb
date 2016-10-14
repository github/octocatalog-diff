require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_bootstrap_script' do
    it 'should set options[:bootstrap_script]' do
      result = run_optparse(['--bootstrap-script', 'my-bootstrap-script'])
      expect(result.fetch(:bootstrap_script, 'key-not-defined')).to eq('my-bootstrap-script')
    end
  end
end
