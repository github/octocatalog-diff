# frozen_string_literal: true

require_relative '../spec_helper'

require OctocatalogDiff::Spec.require_path('/cli/fact_override')
require 'json'

describe OctocatalogDiff::Cli::FactOverride do
  context 'with faulty input' do
    describe '#fact_override' do
      it 'should raise ArgumentError when string lacks an =' do
        arg = 'dkfjladksfjaldfjdslkfjads'
        expect do
          _foo = OctocatalogDiff::Cli::FactOverride.fact_override(arg)
        end.to raise_error(ArgumentError, /Fact override.*is not in 'key=\(data type\)value' format/)
      end

      it 'should raise ArgumentError when non-string lacks a key' do
        arg = ['dkfjladksfjaldfjdslkfjads']
        expect do
          _foo = OctocatalogDiff::Cli::FactOverride.fact_override(arg)
        end.to raise_error(ArgumentError, /Define a key when the input is not a string/)
      end

      it 'should raise JSON::ParserError if JSON fails to parse' do
        arg = 'key=(json){akdsfjalsdkfjasdf}'
        expect do
          _foo = OctocatalogDiff::Cli::FactOverride.fact_override(arg)
        end.to raise_error(JSON::ParserError, /unexpected token at '\{akdsfjalsdkfjasdf\}'/)
      end

      it 'should raise ArgumentError when unrecognized data type is specified' do
        arg = 'key=(chicken)blahblah'
        expect do
          _foo = OctocatalogDiff::Cli::FactOverride.fact_override(arg)
        end.to raise_error(ArgumentError, /Unknown data type 'chicken'/)
      end

      it 'should raise ArgumentError when boolean is specified but not supplied' do
        arg = 'key=(boolean)blahblah'
        expect do
          _foo = OctocatalogDiff::Cli::FactOverride.fact_override(arg)
        end.to raise_error(ArgumentError, /Illegal boolean 'blahblah'/)
      end

      it 'should raise ArgumentError when fixnum is specified but not supplied' do
        arg = 'key=(fixnum)blahblah'
        expect do
          _foo = OctocatalogDiff::Cli::FactOverride.fact_override(arg)
        end.to raise_error(ArgumentError, /Illegal fixnum 'blahblah'/)
      end

      it 'should raise ArgumentError when float is specified but not supplied' do
        arg = 'key=(float)blahblah'
        expect do
          _foo = OctocatalogDiff::Cli::FactOverride.fact_override(arg)
        end.to raise_error(ArgumentError, /Illegal float 'blahblah'/)
      end
    end
  end

  context 'with proper typed input' do
    describe '#new' do
      it 'should pass through a string' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=(string)chicken')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq('chicken')
      end

      it 'should pass through an empty string' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=(string)')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq('')
      end

      it 'should pass through a multi-line string' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override("foo=(string)foo\nbar")
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq("foo\nbar")
      end

      it 'should pass through a positive integer' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=(fixnum)42')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(42)
      end

      it 'should pass through a negative integer' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=(fixnum)-42')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(-42)
      end

      it 'should pass through a positive float' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=(float)42.15')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(42.15)
      end

      it 'should pass through a negative float' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=(float)-42.15')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(-42.15)
      end

      it 'should pass through a positive float with no leading digit' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=(float).15')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(0.15)
      end

      it 'should pass through a negative float with no leading digit' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=(float)-.15')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(-0.15)
      end

      it 'should handle true boolean' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=(boolean)true')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(true)
      end

      it 'should handle true boolean case-insensitive' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=(boolean)TrUe')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(true)
      end

      it 'should handle false boolean' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=(boolean)false')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(false)
      end

      it 'should handle false boolean case-insensitive' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=(boolean)FaLsE')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(false)
      end

      it 'should parse JSON' do
        arg = 'foo=(json){"bar":"baz"}'
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override(arg)
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq('bar' => 'baz')
      end

      it 'should return string even when input looks like a number' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=(string)42')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq('42')
      end

      it 'should return string even when input looks like a float' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=(string)42.15')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq('42.15')
      end

      it 'should return string even when input looks like a boolean' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=(string)true')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq('true')
      end

      it 'shouuld pass through a nil with no argument' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=(nil)')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(nil)
      end

      it 'should pass through a nil with superfluous argument' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=(nil)blahblahblah')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(nil)
      end
    end
  end

  context 'with proper guessed string input' do
    describe '#new' do
      it 'should pass through a string' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=chicken')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq('chicken')
      end

      it 'should pass through an empty string' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq('')
      end

      it 'should pass through a multi-line string' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override("foo=foo\nbar")
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq("foo\nbar")
      end

      it 'should pass through a positive integer' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=42')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(42)
      end

      it 'should pass through a negative integer' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=-42')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(-42)
      end

      it 'should pass through a positive float' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=42.15')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(42.15)
      end

      it 'should pass through a negative float' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=-42.15')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(-42.15)
      end

      it 'should pass through a positive float with no leading digit' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=.15')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(0.15)
      end

      it 'should pass through a negative float with no leading digit' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=-.15')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(-0.15)
      end

      it 'should handle true boolean' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=true')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(true)
      end

      it 'should handle true boolean case-insensitive' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=TrUe')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(true)
      end

      it 'should handle false boolean' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=false')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(false)
      end

      it 'should handle false boolean case-insensitive' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override('foo=FaLsE')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(false)
      end
    end
  end

  context 'with non-string input' do
    describe '#new' do
      it 'should pass through a fixnum without manipulation' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override(42, 'foo')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(42)
      end

      it 'should pass through a float without manipulation' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override(42.15, 'foo')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(42.15)
      end

      it 'should pass through a boolean without manipulation' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override(false, 'foo')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(false)
      end

      it 'should pass through a nil without manipulation' do
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override(nil, 'foo')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(nil)
      end

      it 'should pass through a hash without manipulation' do
        arg = { 'foo' => 'bar', 'baz' => [1, 2, 3, 4, 5] }
        testobj = OctocatalogDiff::Cli::FactOverride.fact_override(arg, 'foo')
        expect(testobj.key).to eq('foo')
        expect(testobj.value).to eq(arg)
      end
    end
  end
end
