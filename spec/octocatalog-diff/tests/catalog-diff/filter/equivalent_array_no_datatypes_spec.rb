# frozen_string_literal: true

require_relative '../../spec_helper'
require OctocatalogDiff::Spec.require_path('/api/v1/diff')
require OctocatalogDiff::Spec.require_path('/catalog-diff/filter/equivalent_array_no_datatypes')

describe OctocatalogDiff::CatalogDiff::Filter::EquivalentArrayNoDatatypes do
  let(:subject) { described_class.new }

  describe '#filtered?' do
    it 'should not filter out an added resource' do
      diff = ['+', "Exec\fmy-command", { 'parameters' => { 'returns' => [0, 1] } }]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end

    it 'should not filter out a removed resource' do
      diff = ['-', "Exec\fmy-command", { 'parameters' => { 'returns' => [0, 1] } }]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end

    it 'should not filter when old value is not an array' do
      diff = [
        '~',
        "Exec\fmy-command\fparameters\freturns",
        '1',
        [1]
      ]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end

    it 'should not filter when new value is not an array' do
      diff = [
        '~',
        "Exec\fmy-command\fparameters\freturns",
        ['1'],
        '1'
      ]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end

    it 'should not filter when arrays have different sizes' do
      diff = [
        '~',
        "Exec\fmy-command\fparameters\freturns",
        %w[1 2],
        [1, 2, 3]
      ]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end

    it 'should filter for identical arrays' do
      diff = [
        '~',
        "Exec\fmy-command\fparameters\freturns",
        [0, 1],
        [0, 1]
      ]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(true)
    end

    it 'should filter for integers, floats, and strings in arrays' do
      diff = [
        '~',
        "Exec\fmy-command\fparameters\freturns",
        ['0', 1, 3.14159, '-4', '0.222', '.333', '-1.444', '5.555'],
        [0, '1', '3.14159', -4, 0.222, 0.333, -1.444, 5.555]
      ]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(true)
    end

    it 'should filter integer-value floats and equivalent integers' do
      diff = [
        '~',
        "Exec\fmy-command\fparameters\freturns",
        ['0.000', 1, -3],
        [0, 1.0, -3.000]
      ]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(true)
    end

    it 'should filter symbols' do
      diff = [
        '~',
        "Exec\fmy-command\fparameters\freturns",
        [:foo, ':bar'],
        [':foo', :bar]
      ]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(true)
    end

    it 'should not filter data structures' do
      diff = [
        '~',
        "Exec\fmy-command\fparameters\freturns",
        [[], {}],
        [{}, []]
      ]
      diff_obj = OctocatalogDiff::API::V1::Diff.new(diff)
      result = subject.filtered?(diff_obj)
      expect(result).to eq(false)
    end
  end
end
