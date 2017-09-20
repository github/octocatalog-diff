# frozen_string_literal: true

require_relative '../../spec_helper'

require OctocatalogDiff::Spec.require_path('/api/v1/override')

describe OctocatalogDiff::API::V1::Override do
  describe '#new' do
    it 'should raise error if fact name is not supplied' do
      expect { described_class.new(value: 'bar') }.to raise_error(KeyError, /key/)
    end

    it 'should raise error if value is not supplied' do
      expect { described_class.new(key: 'bar') }.to raise_error(KeyError, /value/)
    end

    it 'should return a regexp if fact name is a regexp' do
      testobj = described_class.new(key: '/foo/', value: 'bar')
      expect(testobj.key).to eq(/foo/)
      expect(testobj.value).to eq('bar')
    end
  end

  describe '#key' do
    it 'should return fact_name' do
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

  context 'with proper typed input' do
    describe '#new' do
      it 'should pass through a string' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '(string)chicken')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq('chicken')
      end

      it 'should pass through an empty string' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '(string)')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq('')
      end

      it 'should pass through a multi-line string' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: "(string)foo\nbar")
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq("foo\nbar")
      end

      it 'should pass through a positive integer using fixnum' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '(fixnum)42')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(42)
      end

      it 'should pass through a positive integer using integer' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '(integer)42')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(42)
      end

      it 'should pass through a negative integer' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '(integer)-42')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(-42)
      end

      it 'should pass through a positive float' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '(float)42.15')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(42.15)
      end

      it 'should pass through a negative float' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '(float)-42.15')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(-42.15)
      end

      it 'should pass through a positive float with no leading digit' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '(float).15')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(0.15)
      end

      it 'should pass through a negative float with no leading digit' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '(float)-.15')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(-0.15)
      end

      it 'should handle true boolean' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '(boolean)true')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(true)
      end

      it 'should handle true boolean case-insensitive' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '(boolean)TrUe')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(true)
      end

      it 'should handle false boolean' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '(boolean)false')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(false)
      end

      it 'should handle false boolean case-insensitive' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '(boolean)FaLsE')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(false)
      end

      it 'should parse JSON' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '(json){"bar":"baz"}')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq('bar' => 'baz')
      end

      it 'should return string even when input looks like a number' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '(string)42')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq('42')
      end

      it 'should return string even when input looks like a float' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '(string)42.15')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq('42.15')
      end

      it 'should return string even when input looks like a boolean' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '(string)true')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq('true')
      end

      it 'shouuld pass through a nil with no argument' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '(nil)')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(nil)
      end

      it 'should pass through a nil with superfluous argument' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '(nil)blahblahblah')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(nil)
      end
    end
  end

  context 'with proper guessed string input' do
    describe '#new' do
      it 'should pass through a string' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: 'chicken')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq('chicken')
      end

      it 'should pass through an empty string' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq('')
      end

      it 'should pass through a multi-line string' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: "foo\nbar")
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq("foo\nbar")
      end

      it 'should pass through a positive integer' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '42')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(42)
      end

      it 'should pass through a negative integer' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '-42')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(-42)
      end

      it 'should pass through a positive float' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '42.15')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(42.15)
      end

      it 'should pass through a negative float' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '-42.15')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(-42.15)
      end

      it 'should pass through a positive float with no leading digit' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '.15')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(0.15)
      end

      it 'should pass through a negative float with no leading digit' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: '-.15')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(-0.15)
      end

      it 'should handle true boolean' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: 'true')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(true)
      end

      it 'should handle true boolean case-insensitive' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: 'TrUe')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(true)
      end

      it 'should handle false boolean' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: 'false')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(false)
      end

      it 'should handle false boolean case-insensitive' do
        testobj = OctocatalogDiff::API::V1::Override.new(key: 'foo', value: 'FaLsE')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(false)
      end
    end
  end

  describe '#create_from_input' do
    it 'should raise ArgumentError when string lacks an =' do
      arg = 'dkfjladksfjaldfjdslkfjads'
      expect do
        _foo = described_class.create_from_input(arg)
      end.to raise_error(ArgumentError, /Fact override.*is not in 'key=\(data type\)value' format/)
    end

    it 'should raise ArgumentError when non-string lacks a key' do
      arg = ['dkfjladksfjaldfjdslkfjads']
      expect do
        _foo = described_class.create_from_input(arg)
      end.to raise_error(ArgumentError, /Define a key when the input is not a string/)
    end

    it 'should raise JSON::ParserError if JSON fails to parse' do
      arg = 'key=(json){akdsfjalsdkfjasdf}'
      expect do
        _foo = described_class.create_from_input(arg)
      end.to raise_error(JSON::ParserError, /unexpected token at '\{akdsfjalsdkfjasdf\}'/)
    end

    it 'should raise ArgumentError when unrecognized data type is specified' do
      arg = 'key=(chicken)blahblah'
      expect do
        _foo = described_class.create_from_input(arg)
      end.to raise_error(ArgumentError, /Unknown data type 'chicken'/)
    end

    it 'should raise ArgumentError when boolean is specified but not supplied' do
      arg = 'key=(boolean)blahblah'
      expect do
        _foo = described_class.create_from_input(arg)
      end.to raise_error(ArgumentError, /Illegal boolean 'blahblah'/)
    end

    it 'should raise ArgumentError when integer is specified but not supplied' do
      arg = 'key=(integer)blahblah'
      expect do
        _foo = described_class.create_from_input(arg)
      end.to raise_error(ArgumentError, /Illegal integer 'blahblah'/)
    end

    it 'should raise ArgumentError when float is specified but not supplied' do
      arg = 'key=(float)blahblah'
      expect do
        _foo = described_class.create_from_input(arg)
      end.to raise_error(ArgumentError, /Illegal float 'blahblah'/)
    end

    it 'should return constructed object when given a string' do
      result = described_class.create_from_input('foo=(string)bar')
      expect(result).to be_a_kind_of(OctocatalogDiff::API::V1::Override)
      expect(result.key).to eq('foo')
      expect(result.value).to eq('bar')
    end

    it 'should return constructed object when given a key and a string' do
      result = described_class.create_from_input('foo=(string)bar', 'my_key_name')
      expect(result).to be_a_kind_of(OctocatalogDiff::API::V1::Override)
      expect(result.key).to eq('my_key_name')
      expect(result.value).to eq('foo=(string)bar')
    end
  end
end
