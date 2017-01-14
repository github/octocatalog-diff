# frozen_string_literal: true

require_relative '../../spec_helper'

require OctocatalogDiff::Spec.require_path('/api/v1/fact_override')

describe OctocatalogDiff::API::V1::FactOverride do
  describe '#new' do
    it 'should raise error if fact_name is not supplied' do
      expect { described_class.new(value: 'bar') }.to raise_error(KeyError, /fact_name/)
    end

    it 'should raise error if value is not supplied' do
      expect { described_class.new(fact_name: 'bar') }.to raise_error(KeyError, /value/)
    end
  end

  describe '#fact_name' do
    it 'should return fact_name' do
      testobj = described_class.new(fact_name: 'foo', value: 'bar')
      expect(testobj.fact_name).to eq('foo')
    end
  end

  describe '#key' do
    it 'should return fact_name' do
      testobj = described_class.new(fact_name: 'foo', value: 'bar')
      expect(testobj.key).to eq('foo')
    end
  end

  describe '#value' do
    it 'should return value' do
      testobj = described_class.new(fact_name: 'foo', value: 'bar')
      expect(testobj.value).to eq('bar')
    end
  end
end
