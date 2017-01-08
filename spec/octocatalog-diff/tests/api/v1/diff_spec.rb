# frozen_string_literal: true

require_relative '../../spec_helper'

require OctocatalogDiff::Spec.require_path('/api/v1/diff')

describe OctocatalogDiff::API::V1::Diff do
  let(:type_title) { "File\f/etc/foo" }
  let(:parameters) { { 'parameters' => { 'owner' => 'root' } } }
  let(:tts) { "File\f/etc/foo\fparameters\fcontent" }

  let(:loc_1) { { 'file' => '/var/tmp/foo.pp', 'line' => 35 } }
  let(:loc_2) { { 'file' => '/var/tmp/foo.pp', 'line' => 12 } }

  let(:add_1) { ['+', type_title, parameters] }
  let(:add_2) { ['+', type_title, parameters, loc_1] }

  let(:del_1) { ['-', type_title, parameters] }
  let(:del_2) { ['-', type_title, parameters, loc_1] }

  let(:chg_1) { ['~', tts, 'old', 'new'] }
  let(:chg_2) { ['~', tts, 'old', 'new', loc_1, loc_2] }

  describe '#[]' do
    it 'should return expected numeric values from an add/remove array' do
      testobj = described_class.new(add_1)
      expect(testobj[0]).to eq('+')
      expect(testobj[1]).to eq(type_title)
      expect(testobj[2]).to eq(parameters)
      expect(testobj[3]).to be_nil
    end

    it 'should return expected numeric values from a change array' do
      testobj = described_class.new(chg_2)
      expect(testobj[0]).to eq('~')
      expect(testobj[1]).to eq(tts)
      expect(testobj[2]).to eq('old')
      expect(testobj[3]).to eq('new')
      expect(testobj[4]).to eq(loc_1)
      expect(testobj[5]).to eq(loc_2)
      expect(testobj[6]).to be_nil
    end
  end

  describe '#change_type' do
    it 'should identify the symbol' do
      testobj = described_class.new(chg_2)
      expect(testobj.change_type).to eq('~')
    end
  end

  describe '#change_type_word' do
    it 'should identify addition' do
      testobj = described_class.new(add_1)
      expect(testobj.change_type_word).to eq('addition')
    end

    it 'should identify removal' do
      testobj = described_class.new(del_1)
      expect(testobj.change_type_word).to eq('removal')
    end

    it 'should identify change with ~' do
      testobj = described_class.new(chg_1)
      expect(testobj.change_type_word).to eq('change')
    end

    it 'should identify change with !' do
      x = chg_1.dup
      x[0] = '!'
      testobj = described_class.new(x)
      expect(testobj.change_type_word).to eq('change')
    end

    it 'should raise ArgumentError for unknown symbol' do
      x = chg_1.dup
      x[0] = '#'
      testobj = described_class.new(x)
      expect { testobj.change_type_word }.to raise_error(ArgumentError)
    end
  end

  describe '#type_title' do
  end

  describe '#type' do
  end

  describe '#title' do
  end

  describe '#structure' do
  end

  describe '#old_value' do
  end

  describe '#new_value' do
  end

  describe '#old_location' do
  end

  describe '#new_location' do
  end

  describe '#old_file' do
  end

  describe '#old_line' do
  end

  describe '#new_file' do
  end

  describe '#new_line' do
  end
end
