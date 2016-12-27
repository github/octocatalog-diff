# frozen_string_literal: true

require_relative 'integration_helper'
require_relative '../mocks/puppetdb'

describe 'catalog from puppetdb integration' do
  let(:disabled_regex) { Regexp.new('Disabling --compare-file-text; not supported by OctocatalogDiff::Catalog::PuppetDB') }

  context 'with no changes' do
    before(:each) do
      allow(OctocatalogDiff::PuppetDB).to receive(:new) { |*_arg| OctocatalogDiff::Mocks::PuppetDB.new }
      @result = OctocatalogDiff::Integration.integration(
        spec_repo: 'default',
        spec_fact_file: 'facts.yaml',
        argv: [
          '--from-puppetdb',
          '--to-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/catalog-1-v4.json'),
          '-n', 'catalog-1-puppetdb',
          '--compare-file-text'
        ]
      )
    end

    it 'should build the catalog' do
      expect(@result[:exitcode]).not_to eq(-1), "Internal error: #{OctocatalogDiff::Integration.format_exception(@result)}"
      expect(@result[:exitcode]).to eq(0), "Runtime error: #{@result[:logs]}"
    end

    it 'should warn that --compare-file-text is being disabled' do
      pending 'catalog-diff failed' unless (@result[:exitcode]).zero?
      expect(@result[:logs]).to match(disabled_regex)
    end

    it 'should show 0 diffs' do
      pending 'catalog-diff failed' unless (@result[:exitcode]).zero?
      diffs = OctocatalogDiff::Spec.remove_file_and_line(@result[:diffs])
      expect(diffs.size).to eq(0), diffs.inspect
    end
  end

  context 'with changes' do
    before(:each) do
      allow(OctocatalogDiff::PuppetDB).to receive(:new) { |*_arg| OctocatalogDiff::Mocks::PuppetDB.new }
      @result = OctocatalogDiff::Integration.integration(
        spec_repo: 'default',
        spec_fact_file: 'facts.yaml',
        argv: [
          '--from-puppetdb',
          '--to-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/catalog-2-v4.json'),
          '-n', 'catalog-1-puppetdb',
          '--compare-file-text'
        ]
      )
    end

    it 'should build the catalog' do
      expect(@result[:exitcode]).not_to eq(-1), "Internal error: #{OctocatalogDiff::Integration.format_exception(@result)}"
      expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
    end

    it 'should warn that --compare-file-text is being disabled' do
      pending 'catalog-diff failed' unless @result[:exitcode] == 2
      expect(@result[:logs]).to match(disabled_regex)
    end

    # See spec/octocatalog-diff/tests/catalog-diff/differ_spec.rb for the itemized list of the expected
    # differences between these catalog items. (There are 17 there, but 3 of those are 'Class' differences,
    # which are explicitly ignored via the CLI class.)
    it 'should show 14 diffs' do
      pending 'catalog-diff failed' unless @result[:exitcode] == 2
      expect(@result.diffs).not_to be_nil, @result.inspect
      expect(@result.diffs.size).to eq(14), @result[:diffs].map(&:inspect).join("\n")
    end
  end
end
