# frozen_string_literal: true

require_relative '../tests/spec_helper'

require OctocatalogDiff::Spec.require_path('api/v1/catalog-compile')
require OctocatalogDiff::Spec.require_path('util/catalogs')

describe OctocatalogDiff::API::V1::CatalogCompile do
  context 'with correct command line arguments and working catalog' do
    before(:all) do
      logger, @logger_str = OctocatalogDiff::Spec.setup_logger
      options = {
        logger: logger,
        node: 'rspec-node.github.net',
        bootstrapped_to_dir: OctocatalogDiff::Spec.fixture_path('repos/default'),
        fact_file: OctocatalogDiff::Spec.fixture_path('facts/facts.yaml'),
        puppet_binary: OctocatalogDiff::Spec::PUPPET_BINARY,
        hiera_config: 'config/hiera.yaml',
        hiera_path_strip: '/var/lib/puppet',
        to_env: 'master'
      }
      @result = described_class.catalog(options)
    end

    it 'should return a catalog object' do
      expect(@result).to be_a_kind_of(OctocatalogDiff::Catalog)
    end

    it 'should be a valid catalog' do
      expect(@result.valid?).to eq(true)
    end

    it 'should contain an expected resource' do
      expect(@result.resource(type: 'Ssh_authorized_key', title: 'bob@local')).to be_a_kind_of(Hash)
    end

    it 'should log to the logger' do
      expect(@logger_str.string).to match(/Compiling catalog for rspec-node.github.net/)
      expect(@logger_str.string).to match(/Initialized OctocatalogDiff::Catalog::Noop for from-catalog/)
      expect(@logger_str.string).to match(/Initialized OctocatalogDiff::Catalog::Computed for to-catalog/)
      expect(@logger_str.string).to match(/Catalog for master will be built with OctocatalogDiff::Catalog::Computed/)
      expect(@logger_str.string).to match(/Calling build for object OctocatalogDiff::Catalog::Computed/)
      expect(@logger_str.string).to match(/Catalog for master successfully built with OctocatalogDiff::Catalog::Computed/)
    end
  end

  context 'with correct command line arguments and failing catalog' do
    it 'should raise CatalogError' do
      options = {
        node: 'rspec-node.github.net',
        bootstrapped_to_dir: OctocatalogDiff::Spec.fixture_path('repos/default'),
        fact_file: OctocatalogDiff::Spec.fixture_path('facts/facts.yaml'),
        puppet_binary: OctocatalogDiff::Spec::PUPPET_BINARY,
        to_env: 'master'
      }
      expect do
        described_class.catalog(options)
      end.to raise_error(OctocatalogDiff::Util::Catalogs::CatalogError)
    end
  end

  context 'with incorrect command line arguments' do
    it 'should raise ArgumentError if called without an options hash' do
      expect do
        described_class.catalog
      end.to raise_error(ArgumentError, 'Usage: #catalog(options_hash)')
    end

    it 'should raise ArgumentError if node is not a string' do
      expect do
        described_class.catalog(node: {})
      end.to raise_error(ArgumentError, 'Node name must be passed to OctocatalogDiff::Catalog::Computed')
    end
  end
end
