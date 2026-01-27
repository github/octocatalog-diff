# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../mocks/puppetdb'

require OctocatalogDiff::Spec.require_path('/catalog-util/facts')

require 'json'

describe OctocatalogDiff::CatalogUtil::Facts do
  # Make sure the environment is sanitized between each run
  before(:each) do
    @env_keys = ENV.keys
  end
  after(:each) do
    keys_to_remove = ENV.keys - @env_keys
    keys_to_remove.each { |k| ENV.delete(k) }
  end

  context 'fact object passed in' do
    describe '#facts' do
      it 'should return facts passed directly to it' do
        factsobj = OctocatalogDiff::Facts.new(
          backend: :yaml,
          fact_file_string: File.read(OctocatalogDiff::Spec.fixture_path('facts/facts.yaml'))
        )
        testobj = OctocatalogDiff::CatalogUtil::Facts.new(
          facts: factsobj
        )
        expect(testobj.facts).to eq(factsobj)
      end
    end
  end

  context 'facts from fact directory' do
    describe '#facts' do
      it 'should read a YAML file from fact dir' do
        fact_dir = OctocatalogDiff::Spec.fixture_path('facts')
        testobj = OctocatalogDiff::CatalogUtil::Facts.new(node: 'valid-facts', fact_file_dir: fact_dir)
        answer = OctocatalogDiff::Facts.new(
          backend: :yaml,
          fact_file_string: File.read(OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml')),
          node: 'valid-facts'
        )
        expect(testobj.facts.facts).to eq(answer.facts)
      end

      it 'should read a JSON file from fact dir' do
        fact_dir = OctocatalogDiff::Spec.fixture_path('fact-dirs/json')
        testobj = OctocatalogDiff::CatalogUtil::Facts.new(node: 'rspec-node.xyz.github.net', fact_file_dir: fact_dir)
        answer = OctocatalogDiff::Facts.new(
          backend: :json,
          fact_file_string: File.read(OctocatalogDiff::Spec.fixture_path('fact-dirs/json/rspec-node.xyz.github.net.json')),
          node: 'rspec-node.xyz.github.net'
        )
        expect(testobj.facts.facts).to eq(answer.facts)
      end

      it 'should raise an error when puppetdb_url is also provided' do
        fact_dir = OctocatalogDiff::Spec.fixture_path('facts')
        expect do
          OctocatalogDiff::CatalogUtil::Facts.new(
            node: 'valid-facts',
            fact_file_dir: fact_dir,
            puppetdb_url: 'http://localhost:8080'
          )
        end.to raise_error(ArgumentError)
      end
    end
  end

  context 'facts from YAML' do
    describe '#facts' do
      it 'should read a YAML file and build facts' do
        ENV['PUPPET_FACT_DIR'] = OctocatalogDiff::Spec.fixture_path('facts')
        testobj = OctocatalogDiff::CatalogUtil::Facts.new(node: 'valid-facts')
        answer = OctocatalogDiff::Facts.new(
          backend: :yaml,
          fact_file_string: File.read(OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml')),
          node: 'valid-facts'
        )
        expect(testobj.facts.facts).to eq(answer.facts)
      end
    end
  end

  context 'facts from PuppetDB' do
    describe '#facts' do
      it 'should retrieve facts from PuppetDB' do
        allow(OctocatalogDiff::PuppetDB).to receive(:new) { |*_arg| OctocatalogDiff::Mocks::PuppetDB.new }
        ENV['PUPPETDB_URL'] = 'http://localhost:8080' # Not really used
        testobj = OctocatalogDiff::CatalogUtil::Facts.new(node: 'facts')
        answer = OctocatalogDiff::Facts.new(
          backend: :json,
          fact_file_string: File.read(OctocatalogDiff::Spec.fixture_path('facts/facts.json')),
          node: 'facts'
        )
        expect(testobj.facts.facts).to eq(answer.facts)
      end
    end
  end

  context 'error handling' do
    describe '#facts' do
      it 'should raise an error if node is not set and facts are not provided' do
        expect do
          OctocatalogDiff::CatalogUtil::Facts.new
        end.to raise_error(ArgumentError)
      end

      it 'should raise an error if neither fact directory nor puppetdb info is provided' do
        ENV.delete('PUPPET_FACT_DIR')
        ENV.delete('PUPPETDB_URL')
        expect do
          OctocatalogDiff::CatalogUtil::Facts.new(node: 'foonode').facts
        end.to raise_error(ArgumentError)
      end

      it 'should try puppetdb if an invalid fact directory is provided' do
        ENV['PUPPET_FACT_DIR'] = OctocatalogDiff::Spec.fixture_path('facts/does/not/exist')
        ENV['PUPPETDB_URL'] = 'http://localhost:8080' # Not really used
        allow(OctocatalogDiff::PuppetDB).to receive(:new) do |*_arg|
          OctocatalogDiff::Mocks::PuppetDB.new('facts' => { 'i_am' => 'puppetdb' })
        end
        testobj = OctocatalogDiff::CatalogUtil::Facts.new(node: 'facts')
        expect(testobj.facts.facts).to eq('name' => 'facts', 'values' => { 'i_am' => 'puppetdb' })
      end

      it 'should try puppetdb if fact file for node is not found' do
        ENV['PUPPET_FACT_DIR'] = OctocatalogDiff::Spec.fixture_path('facts')
        ENV['PUPPETDB_URL'] = 'http://localhost:8080' # Not really used
        allow(OctocatalogDiff::PuppetDB).to receive(:new) do |*_arg|
          OctocatalogDiff::Mocks::PuppetDB.new('asdfasfdasdf' => { 'i_am' => 'puppetdb' })
        end
        testobj = OctocatalogDiff::CatalogUtil::Facts.new(node: 'asdfasfdasdf')
        expect(testobj.facts.facts).to eq('name' => 'asdfasfdasdf', 'values' => { 'i_am' => 'puppetdb' })
      end
    end
  end
end
