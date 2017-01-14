# frozen_string_literal: true

require_relative '../../spec_helper'

require OctocatalogDiff::Spec.require_path('/api/v1/fact_override')

describe OctocatalogDiff::API::V1::FactOverride do
  describe '#new' do
    it 'should raise error if key is not supplied' do
      expect { described_class.new(value: 'bar') }.to raise_error(KeyError, /key/)
    end

    it 'should raise error if value is not supplied' do
      expect { described_class.new(key: 'bar') }.to raise_error(KeyError, /value/)
    end
  end

  describe '#key' do
    it 'should return key' do
      testobj = described_class.new(key: 'foo', value: 'bar')
      expect(testobj.key).to eq('foo')
    end
  end

  describe '#value' do
    it 'should return value' do
      testobj = described_class.new(key: 'foo', value: 'bar')
      expect(testobj.value).to eq('bar')
    end
  end
end
