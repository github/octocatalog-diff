# frozen_string_literal: true

require_relative '../spec_helper'
require 'ostruct'
require OctocatalogDiff::Spec.require_path('/util/util')

describe OctocatalogDiff::Util::Util do
  describe '#object_is_any_of?' do
    it 'should return true when object is one of the classes' do
      object = 42
      classes = [String, Hash, Integer]
      expect(described_class.object_is_any_of?(object, classes)).to eq(true)
    end

    it 'should return false when object is not one of the classes' do
      object = :chickens
      classes = [String, Hash, Integer]
      expect(described_class.object_is_any_of?(object, classes)).to eq(false)
    end
  end

  describe '#safe_dup' do
    it 'should work with nil' do
      object = nil
      result = described_class.safe_dup(object)
      expect(object).to eq(result)
    end

    it 'should work with a string' do
      object = 'boots and cats'
      result = described_class.safe_dup(object)
      expect(object).to eq(result)
    end

    it 'should work with a symbol' do
      object = :chickens
      result = described_class.safe_dup(object)
      expect(object).to eq(result)
    end

    it 'should work with an integer' do
      object = 42
      result = described_class.safe_dup(object)
      expect(object).to eq(result)
    end

    it 'should work with a hash' do
      object = { 'foo' => 'bar', 'baz' => 'buzz' }
      result = described_class.safe_dup(object)
      expect(object).to eq(result)
      expect(object.object_id).not_to eq(result.object_id)
    end

    it 'should work with an array' do
      object = %w[foo bar baz buzz]
      result = described_class.safe_dup(object)
      expect(object).to eq(result)
      expect(object.object_id).not_to eq(result.object_id)
    end
  end

  describe '#deep_dup' do
    it 'should dupe a hash' do
      hash1 = { 'foo' => 'bar' }
      hash2 = { 'baz' => hash1 }
      hash3 = { 'xxx' => hash2 }
      result = described_class.deep_dup(hash3)
      expect(result['xxx']).to eq(hash2)
      expect(result['xxx'].object_id).not_to eq(hash2.object_id)
    end

    it 'should dupe an array' do
      array1 = %w[foo bar baz]
      array2 = ['foo', array1, 'baz']
      array3 = ['foo', array2, 'baz']
      result = described_class.deep_dup(array3)
      expect(result[1]).to eq(array2)
      expect(result[1].object_id).not_to eq(array2.object_id)
    end

    it 'should dupe a string' do
      obj = 'Hello there'
      result = described_class.deep_dup(obj)
      expect(result).to eq(obj)
    end
  end

  describe '#temp_dir' do
    after(:all) do
      ENV.delete('OCTOCATALOG_DIFF_TEMPDIR')
    end

    it 'should create a temporary directory when no base directory is specified' do
      ENV.delete('OCTOCATALOG_DIFF_TEMPDIR')
      expect(Dir).to receive(:mktmpdir).with('ocd-').and_return('adsdasdfasdf')
      expect(described_class.temp_dir).to eq('adsdasdfasdf')
    end

    it 'should create a temporary directory within OCTOCATALOG_DIFF_TEMPDIR when specified' do
      ENV['OCTOCATALOG_DIFF_TEMPDIR'] = '/var/tmp/asdfasdfasdf'
      expect(File).to receive(:'directory?').with('/var/tmp/asdfasdfasdf').and_return(true)
      expect(Dir).to receive(:mktmpdir).with('ocd-', '/var/tmp/asdfasdfasdf').and_return('/var/tmp/asdfasdfasdf/qwertyuiop')
      expect(described_class.temp_dir).to eq('/var/tmp/asdfasdfasdf/qwertyuiop')
    end

    it 'should raise an error if OCTOCATALOG_DIFF_TEMPDIR is specified but does not exist' do
      ENV['OCTOCATALOG_DIFF_TEMPDIR'] = '/var/tmp/asdfasdfasdf'
      expect(File).to receive(:'directory?').with('/var/tmp/asdfasdfasdf').and_return(false)
      expect { described_class.temp_dir }.to raise_error(Errno::ENOENT, /temp_dir: Base dir/)
    end
  end
end
