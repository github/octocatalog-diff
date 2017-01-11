# frozen_string_literal: true

require_relative '../spec_helper'
require OctocatalogDiff::Spec.require_path('/catalog')
require OctocatalogDiff::Spec.require_path('/catalog-diff/differ')
require OctocatalogDiff::Spec.require_path('/catalog-diff/display')

require 'json'

describe OctocatalogDiff::CatalogDiff::Display do
  let(:differ) do
    c1 = OctocatalogDiff::Catalog.new(json: File.read(OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog.json')))
    c2 = OctocatalogDiff::Catalog.new(json: File.read(OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog-2.json')))
    OctocatalogDiff::CatalogDiff::Differ.new({}, c1, c2)
  end

  describe '#output' do
    it 'should work with a OctocatalogDiff::CatalogDiff::Differ passed to it' do
      result = OctocatalogDiff::CatalogDiff::Display.output(differ)
      expect(result.first).to eq("\e[0;32;49m+ Class[Fizzbuzz]\e[0m")
    end

    it 'should work with an array of diff results passed to it' do
      diff_array = differ.diff
      result = OctocatalogDiff::CatalogDiff::Display.output(diff_array)
      expect(result.first).to eq("\e[0;32;49m+ Class[Fizzbuzz]\e[0m")
    end

    it 'should pass a header' do
      result = OctocatalogDiff::CatalogDiff::Display.output(differ, header: 'My awesome header')
      expect(result.first).to eq('My awesome header')
    end

    it 'should call OctocatalogDiff::CatalogDiff::Display::Text with colors' do
      result = OctocatalogDiff::CatalogDiff::Display.output(differ, format: :color_text)
      expect(result.first).to eq("\e[0;32;49m+ Class[Fizzbuzz]\e[0m")
    end

    it 'should call OctocatalogDiff::CatalogDiff::Display::Text with no colors' do
      result = OctocatalogDiff::CatalogDiff::Display.output(differ, format: :text)
      expect(result.first).to eq('+ Class[Fizzbuzz]')
    end

    it 'should call OctocatalogDiff::CatalogDiff::Display::LegacyJson' do
      opts = {
        format: :legacy_json,
        header: 'My awesome header'
      }
      answer = [
        [
          '+',
          "Class\fFizzbuzz",
          { 'type' => 'Class', 'title' => 'Fizzbuzz', 'tags' => %w(class fizzbuzz), 'exported' => false },
          { 'file' => nil, 'line' => nil }
        ]
      ]
      result = OctocatalogDiff::CatalogDiff::Display.output(differ, opts)
      parse_result = JSON.parse(result)
      expect(parse_result['diff']).to eq(answer)
      expect(parse_result['header']).to eq('My awesome header')
    end

    it 'should call OctocatalogDiff::CatalogDiff::Display::Json' do
      opts = {
        format: :json,
        header: 'My awesome header'
      }
      answer = [
        {
          'diff_type' => '+',
          'type' => 'Class',
          'title' => 'Fizzbuzz',
          'structure' => [],
          'old_value' => nil,
          'new_value' => { 'type' => 'Class', 'title' => 'Fizzbuzz', 'tags' => %w(class fizzbuzz), 'exported' => false },
          'old_file' => nil,
          'old_line' => nil,
          'new_file' => nil,
          'new_line' => nil,
          'old_location' => nil,
          'new_location' => { 'file' => nil, 'line' => nil }
        }
      ]
      result = OctocatalogDiff::CatalogDiff::Display.output(differ, opts)
      parse_result = JSON.parse(result)
      expect(parse_result['diff']).to eq(answer)
      expect(parse_result['header']).to eq('My awesome header')
    end

    it 'should error when a request format is not supported' do
      opts = {
        format: :aasldfkadfsladfs,
        header: 'My awesome header'
      }
      expect { OctocatalogDiff::CatalogDiff::Display.output(differ, opts) }.to raise_error(ArgumentError)
    end
  end

  context 'Utility methods' do
    describe '#header' do
      it 'should return nil if :no_header is specified' do
        result = OctocatalogDiff::CatalogDiff::Display.output(differ, no_header: true, format: :text)
        expect(result.first).to eq('+ Class[Fizzbuzz]')
      end

      it 'should return header if header is not default' do
        result = OctocatalogDiff::CatalogDiff::Display.output(differ, header: 'my header', format: :text)
        expect(result.first).to eq('my header')
        expect(result[1]).to match(/^\*+$/)
        expect(result[2]).to eq('+ Class[Fizzbuzz]')
      end

      it 'should construct default header when requested' do
        opts = {
          header: :default,
          node: 'nodename',
          from_env: 'from',
          to_env: 'to',
          format: :text
        }
        result = OctocatalogDiff::CatalogDiff::Display.output(differ, opts)
        expect(result.first).to eq('diff from/nodename to/nodename')
        expect(result[1]).to match(/^\*+$/)
        expect(result[2]).to eq('+ Class[Fizzbuzz]')
      end
    end

    describe '#parse_diff_array_into_categorized_hashes' do
      it 'should raise ArgumentError for invalid diff' do
        diff = [[':', "Key\fBad\fFoo\fBar", 'old', 'new']]
        expect do
          OctocatalogDiff::CatalogDiff::Display.parse_diff_array_into_categorized_hashes(diff)
        end.to raise_error(RuntimeError, /Unrecognized diff symbol ':'/)
      end
    end

    describe '#parse_diff_array_into_categorized_hashes' do
      before(:all) do
        diff = [
          ['+', "Key\fAdded", 'added'],
          ['-', "Key\fRemoved", 'removed'],
          ['~', "Key\fChanged\fFoo\fBar", 'old', 'new'],
          ['!', "Key\fNested\fFoo\fBar", 'old', 'new']
        ]
        @result = OctocatalogDiff::CatalogDiff::Display.parse_diff_array_into_categorized_hashes(diff)
      end

      it 'should produce only_in_new correctly' do
        expect(@result[0]).to eq('Key[Added]' => { diff: 'added', loc: nil })
      end

      it 'should produce only_in_old correctly' do
        expect(@result[1]).to eq('Key[Removed]' => { diff: 'removed', loc: nil })
      end

      it 'should produce changed hash correctly' do
        answer = {
          'Key[Changed]' => {
            diff: { 'Foo' => { 'Bar' => { old: 'old', new: 'new' } } },
            old_loc: nil,
            new_loc: nil
          },
          'Key[Nested]' => {
            diff: { 'Foo' => { 'Bar' => { old: 'old', new: 'new' } } },
            old_loc: nil,
            new_loc: nil
          }
        }
        expect(@result[2]).to eq(answer)
      end

      it 'should drop differences where both objects are nil' do
        diff = [
          ['~', "Key\fChanged\fFoo", nil, nil]
        ]
        result = OctocatalogDiff::CatalogDiff::Display.parse_diff_array_into_categorized_hashes(diff)
        expect(result).to eq([{}, {}, {}])
      end
    end
  end
end
