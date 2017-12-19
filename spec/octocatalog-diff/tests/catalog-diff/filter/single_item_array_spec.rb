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
        "File\ffoobar.json\fparameters\fnotify",
        'Service[foo]',
        ['Service[foo]']
      ]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(true)
    end

    it 'should filter when to-catalog has string and from-catalog has array with that string' do
      diff = [
        '~',
        "File\ffoobar.json\fparameters\fnotify",
        ['Service[foo]'],
        'Service[foo]'
      ]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(true)
    end

    it 'should not filter when from-catalog has string and to-catalog has array with a different string' do
      diff = [
        '~',
        "File\ffoobar.json\fparameters\fnotify",
        'Service[bar]',
        ['Service[foo]']
      ]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end

    it 'should not filter when to-catalog has string and from-catalog has array with a different string' do
      diff = [
        '~',
        "File\ffoobar.json\fparameters\fnotify",
        ['Service[foo]'],
        'Service[bar]'
      ]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end

    it 'should not filter when both of the items are arrays' do
      diff = [
        '~',
        "File\ffoobar.json\fparameters\fnotify",
        ['Service[foo]'],
        ['Service[bar]']
      ]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end

    it 'should not filter when both of the items are arrays even if identical' do
      # This diff should never be produced by the program, but catch the edge case anyway.
      diff = [
        '~',
        "File\ffoobar.json\fparameters\fnotify",
        ['Service[foo]'],
        ['Service[foo]']
      ]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end

    it 'should not filter when both of the items are strings even if identical' do
      # This diff should never be produced by the program, but catch the edge case anyway.
      diff = [
        '~',
        "File\ffoobar.json\fparameters\fnotify",
        'Service[foo]',
        'Service[foo]'
      ]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end

    it 'should not filter when one item has an array with multiple elements' do
      diff = [
        '~',
        "File\ffoobar.json",
        "File\ffoobar.json\fparameters\fnotify",
        'Service[foo]',
        ['Service[foo]', 'Service[bar]']
      ]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end
  end
end
