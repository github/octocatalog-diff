# frozen_string_literal: true

require_relative '../spec_helper'
require OctocatalogDiff::Spec.require_path('/api/v1/diff')
require OctocatalogDiff::Spec.require_path('/catalog-diff/filter')

# rubocop:disable Style/ClassAndModuleChildren
class OctocatalogDiff::CatalogDiff::Filter::Fake1 < OctocatalogDiff::CatalogDiff::Filter
end

class OctocatalogDiff::CatalogDiff::Filter::Fake2 < OctocatalogDiff::CatalogDiff::Filter
end
# rubocop:enable Style/ClassAndModuleChildren

describe OctocatalogDiff::CatalogDiff::Filter do
  before(:each) do
    @class_1 = OctocatalogDiff::CatalogDiff::Filter::Fake1
    @class_2 = OctocatalogDiff::CatalogDiff::Filter::Fake2
    allow(Kernel).to receive(:const_get).with('OctocatalogDiff::CatalogDiff::Filter::Fake1').and_return(@class_1)
    allow(Kernel).to receive(:const_get).with('OctocatalogDiff::CatalogDiff::Filter::Fake2').and_return(@class_2)
  end

  describe '#filter?' do
    it 'should return false for non-existent filter' do
      expect(described_class.filter?('BlahBlahBlah')).to eq(false)
    end

    it 'should return true for valid filter' do
      expect(described_class.filter?('AbsentFile')).to eq(true)
    end
  end

  describe '#assert_that_filter_exists' do
    it 'should raise error for non-existent filter' do
      expect do
        described_class.assert_that_filter_exists('BlahBlahBlah')
      end.to raise_error(ArgumentError, 'The filter BlahBlahBlah is not valid')
    end

    it 'should not raise error for valid filter' do
      expect { described_class.assert_that_filter_exists('AbsentFile') }.not_to raise_error
    end
  end

  describe '#apply_filters' do
    it 'should call self.filter() with appropriate options for each class' do
      diff1 = OctocatalogDiff::API::V1::Diff.new(['-', "File\f/tmp/foo"])
      result = [diff1]
      options = { foo: 'bar' }
      classes = %w(Fake1 Fake2)
      allow(described_class).to receive(:"filter?").with('Fake1').and_return(true)
      allow(described_class).to receive(:"filter?").with('Fake2').and_return(true)
      expect_any_instance_of(@class_1).to receive(:'filtered?').with(diff1, foo: 'bar').and_return(false)
      expect_any_instance_of(@class_2).to receive(:'filtered?').with(diff1, foo: 'bar').and_return(false)
      expect { described_class.apply_filters(result, classes, options) }.not_to raise_error
      expect(result).to eq([diff1])
    end
  end

  describe '#filter' do
    it 'should call .filtered?() in a class and remove matching items' do
      diff1 = OctocatalogDiff::API::V1::Diff.new(['-', "File\f/tmp/foo"])
      diff2 = OctocatalogDiff::API::V1::Diff.new(['+', "File\f/tmp/foo"])
      result = [diff1, diff2]
      allow(described_class).to receive(:"filter?").with('Fake1').and_return(true)
      allow(described_class).to receive(:"filter?").with('Fake2').and_return(true)
      expect_any_instance_of(@class_1).to receive(:'filtered?').with(diff1, {}).and_return(false)
      expect_any_instance_of(@class_1).to receive(:'filtered?').with(diff2, {}).and_return(true)
      expect { described_class.filter(result, 'Fake1') }.not_to raise_error
      expect(result).to eq([diff1])
    end
  end

  describe '#filtered?' do
    it 'should raise error' do
      testobj = described_class.new
      expect { testobj.filtered?([]) }.to raise_error(RuntimeError, /No `filtered\?` method is implemented/)
    end
  end
end
