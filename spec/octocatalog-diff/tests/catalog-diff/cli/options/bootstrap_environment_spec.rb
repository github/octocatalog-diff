# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_bootstrap_environment' do
    it 'should not set options[:bootstrap_environment] if no environment variables are set' do
      result = run_optparse(['--bootstrap-script', 'my-bootstrap-script'])
      expect(result.fetch(:bootstrap_environment, 'key-not-defined')).to eq('key-not-defined')
    end

    it 'should error if --bootstrap-environment is passed with no values' do
      expect { run_optparse(['--bootstrap-environment']) }.to raise_error(OptionParser::MissingArgument)
    end

    it 'should set a single bootstrap-environment variable' do
      result = run_optparse(['--bootstrap-environment', 'foo=bar'])
      expect(result[:bootstrap_environment]).to eq('foo' => 'bar')
    end

    it 'should set two bootstrap-environment variables separated by commas' do
      result = run_optparse(['--bootstrap-environment', 'foo=bar,baz=buzz'])
      expect(result[:bootstrap_environment]).to eq('foo' => 'bar', 'baz' => 'buzz')
    end

    it 'should set two bootstrap-environment variables as separate arguments' do
      result = run_optparse(['--bootstrap-environment', 'foo=bar', '--bootstrap-environment', 'baz=buzz'])
      expect(result[:bootstrap_environment]).to eq('foo' => 'bar', 'baz' => 'buzz')
    end

    it 'should error when a bootstrap variable is not in key=value format' do
      expect { run_optparse(['--bootstrap-environment', 'foobar']) }.to raise_error(ArgumentError)
    end

    it 'should strip quotes off value' do
      result = run_optparse(['--bootstrap-environment', 'foo="bar"'])
      expect(result[:bootstrap_environment]).to eq('foo' => 'bar')
    end

    it 'should strip single quotes off value' do
      result = run_optparse(['--bootstrap-environment', "foo='bar'"])
      expect(result[:bootstrap_environment]).to eq('foo' => 'bar')
    end
  end
end
