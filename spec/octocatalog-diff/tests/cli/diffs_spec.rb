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

    it 'should remove tagged-for-ignore resources' do
      cat1 = OctocatalogDiff::Catalog.new(json: File.read(OctocatalogDiff::Spec.fixture_path('catalogs/ignore-tags-old.json')))
      cat2 = OctocatalogDiff::Catalog.new(json: File.read(OctocatalogDiff::Spec.fixture_path('catalogs/ignore-tags-new.json')))
      opts = { ignore_tags: ['ignored_catalog_diff'] }
      answer = JSON.parse(File.read(OctocatalogDiff::Spec.fixture_path('diffs/ignore-tags-partial.json')))
      obj = OctocatalogDiff::Cli::Diffs.new(opts, @logger)
      diffs = obj.diffs(from: cat1, to: cat2)
      expect(diffs.size).to eq(8)
      answer.each do |x|
        expect(diffs).to include(x), "Does not contain: #{x}"
      end
      expect(@logger_str.string).to match(/Ignoring type='Mymodule::Resource1', title='one' based on tag in to-catalog/)
      r = %r{Ignoring type='File', title='/tmp/old-file/ignored/one' based on tag in from-catalog}
      expect(@logger_str.string).to match(r)
    end
  end
end
