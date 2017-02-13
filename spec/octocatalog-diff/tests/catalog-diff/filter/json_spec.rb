# frozen_string_literal: true

require_relative '../../spec_helper'
require OctocatalogDiff::Spec.require_path('/api/v1/diff')
require OctocatalogDiff::Spec.require_path('/catalog-diff/filter/json')

describe OctocatalogDiff::CatalogDiff::Filter::JSON do
  let(:subject) { described_class.new }

  describe '#filtered?' do
    let(:str1a) { '{"foo":"bar"}' }
    let(:str1b) { "{\n  \"foo\": \"bar\"\n}\n" }
    let(:str2) { '{"foo":"baz"}' }

    it 'should not filter out an added resource' do
      diff = ['+', "File\ffoobar.json", { 'parameters' => { 'content' => str1a } }]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end

    it 'should not filter out a removed resource' do
      diff = ['-', "File\ffoobar.json", { 'parameters' => { 'content' => str1a } }]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end

    it 'should not filter out a non-file resource' do
      diff = ['~', "Exec\ffoobar.json\fparameters\fcontent", str1a, str1b]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end

    it 'should not filter out a file whose extension is not .json' do
      diff = ['~', "File\ffoobar.txt\fparameters\fcontent", str1a, str1b]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end

    it 'should not filter out a change with no content change' do
      diff = ['~', "File\ffoobar.json\fparameters\fowner", 'root', 'nobody']
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end

    it 'should not filter out a change where JSON objects are dissimilar' do
      diff = ['~', "File\ffoobar.json\fparameters\fcontent", str1a, str2]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end

    it 'should not filter out a change where JSON is invalid' do
      x_str = '---{ "blah": "foo" }'
      diff = ['~', "File\ffoobar.json\fparameters\fcontent", x_str, x_str]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end

    it 'should not filter out a change where JSON is unparseable' do
      x_str = "--- !ruby/object:This::Does::Not::Exist\n  foo: bar"
      diff = ['~', "File\ffoobar.json\fparameters\fcontent", x_str, x_str]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end

    it 'should filter out a whitespace-only change to a .json file' do
      diff = ['~', "File\ffoobar.json\fparameters\fcontent", str1a, str1b]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(true)
    end
  end
end
