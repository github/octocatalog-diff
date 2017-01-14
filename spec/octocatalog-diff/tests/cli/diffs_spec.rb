# frozen_string_literal: true

require_relative '../spec_helper'

require OctocatalogDiff::Spec.require_path('/cli/diffs')

require 'json'

describe OctocatalogDiff::Cli::Diffs do
  before(:all) do
    @cat_tiny_1 = OctocatalogDiff::Catalog.new(
      node: 'my.rspec.node',
      basedir: '/path/to/catalog1',
      json: File.read(OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog.json'))
    )
    @cat_tiny_2 = OctocatalogDiff::Catalog.new(
      node: 'my.rspec.node',
      basedir: '/path/to/catalog2',
      json: File.read(OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog-2.json'))
    )
    @cat_tiny_tags = OctocatalogDiff::Catalog.new(
      node: 'my.rspec.node',
      basedir: '/path/to/catalog2',
      json: File.read(OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog-tags.json'))
    )
  end

  before(:each) do
    @logger, @logger_str = OctocatalogDiff::Spec.setup_logger
  end

  describe '#diffs' do
    it 'should pass catalogs to OctocatalogDiff::CatalogDiff::Differ' do
      opts = {}
      answer = [['+',
                 "Class\fFizzbuzz",
                 { 'type' => 'Class', 'title' => 'Fizzbuzz', 'tags' => %w(class fizzbuzz), 'exported' => false },
                 { 'file' => nil, 'line' => nil }]]
      testobj = OctocatalogDiff::Cli::Diffs.new(opts, @logger)
      result = testobj.diffs(from: @cat_tiny_1, to: @cat_tiny_2)
      expect(result).to eq(answer)
      expect(@logger_str.string).not_to match(/WARN/)
    end

    it 'should suppress tags when :include_tags is false' do
      opts = { include_tags: false }
      testobj = OctocatalogDiff::Cli::Diffs.new(opts, @logger)
      result = testobj.diffs(from: @cat_tiny_1, to: @cat_tiny_tags)
      expect(result).to eq([])
      expect(@logger_str.string).not_to match(/WARN/)
    end

    it 'should suppress tags when :include_tags is true' do
      opts = { include_tags: true }
      loc_map = { 'file' => nil, 'line' => nil }
      answer = [['!', "Stage\fmain\ftags", ['stage'], ['blah::foo', 'stage'], loc_map, loc_map]]
      testobj = OctocatalogDiff::Cli::Diffs.new(opts, @logger)
      result = testobj.diffs(from: @cat_tiny_1, to: @cat_tiny_tags)
      expect(result).to eq(answer)
      expect(@logger_str.string).not_to match(/WARN/)
    end

    it 'should pass ignore options' do
      opts = { ignore: { type: 'Class', title: 'Fizzbuzz' } }
      testobj = OctocatalogDiff::Cli::Diffs.new(opts, @logger)
      result = testobj.diffs(from: @cat_tiny_1, to: @cat_tiny_2)
      expect(result).to eq([])
      expect(@logger_str.string).not_to match(/WARN/)
    end
  end
end
