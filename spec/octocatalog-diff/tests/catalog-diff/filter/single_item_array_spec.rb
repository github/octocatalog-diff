# frozen_string_literal: true

require_relative '../../spec_helper'
require OctocatalogDiff::Spec.require_path('/api/v1/diff')
require OctocatalogDiff::Spec.require_path('/catalog-diff/filter/single_item_array')

describe OctocatalogDiff::CatalogDiff::Filter::SingleItemArray do
  let(:subject) { described_class.new }

  describe '#filtered?' do
    it 'should not filter out an added resource' do
      diff = ['+', "File\ffoobar.json", { 'parameters' => { 'content' => '{"foo":"bar"}' } }]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end

    it 'should not filter out a removed resource' do
      diff = ['-', "File\ffoobar.json", { 'parameters' => { 'content' => '{"foo":"bar"}' } }]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end

    it 'should filter when from-catalog has string and to-catalog has array with that string' do
      diff = [
        '~',
        "File\ffoobar.json",
        { 'parameters' => { 'notify' => 'Service[foo]' } },
        { 'parameters' => { 'notify' => ['Service[foo]'] } }
      ]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(true)
    end

    it 'should filter when from-catalog has string and to-catalog has array with that string' do
      diff = [
        '~',
        "File\ffoobar.json",
        { 'parameters' => { 'notify' => ['Service[foo]'] } },
        { 'parameters' => { 'notify' => 'Service[foo]' } }
      ]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(true)
    end
  end
end
