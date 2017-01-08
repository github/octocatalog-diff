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
  let(:add_2) { ['+', type_title, parameters, loc_2] }

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

  describe '#diff_type' do
    it 'should identify the symbol' do
      testobj = described_class.new(chg_2)
      expect(testobj.diff_type).to eq('~')
    end
  end

  describe '#addition?' do
    it 'should return true for an addition' do
      testobj = described_class.new(add_2)
      expect(testobj.addition?).to eq(true)
    end

    it 'should return false for a removal' do
      testobj = described_class.new(del_2)
      expect(testobj.addition?).to eq(false)
    end

    it 'should return false for a change' do
      testobj = described_class.new(chg_2)
      expect(testobj.addition?).to eq(false)
    end
  end

  describe '#removal?' do
    it 'should return true for an addition' do
      testobj = described_class.new(add_2)
      expect(testobj.removal?).to eq(false)
    end

    it 'should return false for a removal' do
      testobj = described_class.new(del_2)
      expect(testobj.removal?).to eq(true)
    end

    it 'should return false for a change' do
      testobj = described_class.new(chg_2)
      expect(testobj.removal?).to eq(false)
    end
  end

  describe '#change?' do
    it 'should return true for an addition' do
      testobj = described_class.new(add_2)
      expect(testobj.change?).to eq(false)
    end

    it 'should return false for a removal' do
      testobj = described_class.new(del_2)
      expect(testobj.change?).to eq(false)
    end

    it 'should return false for a change' do
      testobj = described_class.new(chg_2)
      expect(testobj.change?).to eq(true)
    end
  end

  describe '#type' do
    it 'should return the type' do
      testobj = described_class.new(chg_2)
      expect(testobj.type).to eq('File')
    end
  end

  describe '#title' do
    it 'should return the title when there is no structure' do
      testobj = described_class.new(add_2)
      expect(testobj.title).to eq('/etc/foo')
    end

    it 'should return the title when there is structure' do
      testobj = described_class.new(chg_2)
      expect(testobj.title).to eq('/etc/foo')
    end
  end

  describe '#structure' do
    it 'should return an empty array for an addition' do
      testobj = described_class.new(add_2)
      expect(testobj.structure).to eq([])
    end

    it 'should return the proper array for a change' do
      testobj = described_class.new(chg_2)
      expect(testobj.structure).to eq(%w(parameters content))
    end
  end

  describe '#old_value' do
    it 'should return nil for an addition' do
      testobj = described_class.new(add_2)
      expect(testobj.old_value).to be_nil
    end

    it 'should return the entire structure for a removal' do
      testobj = described_class.new(del_2)
      expect(testobj.old_value).to eq(parameters)
    end

    it 'should return the old value for a change' do
      testobj = described_class.new(chg_2)
      expect(testobj.old_value).to eq('old')
    end
  end

  describe '#new_value' do
    it 'should return the entire structure for an addition' do
      testobj = described_class.new(add_2)
      expect(testobj.new_value).to eq(parameters)
    end

    it 'should return nil for a removal' do
      testobj = described_class.new(del_2)
      expect(testobj.new_value).to be_nil
    end

    it 'should return the new value for a change' do
      testobj = described_class.new(chg_2)
      expect(testobj.new_value).to eq('new')
    end
  end

  describe '#old_file' do
    it 'should return nil for an addition' do
      testobj = described_class.new(add_2)
      expect(testobj.old_file).to be_nil
    end

    it 'should return the filename for a removal' do
      testobj = described_class.new(del_2)
      expect(testobj.old_file).to eq(loc_1['file'])
    end

    it 'should return nil when information is not present for a removal' do
      testobj = described_class.new(del_1)
      expect(testobj.old_file).to be_nil
    end

    it 'should return the filename for a change' do
      testobj = described_class.new(chg_2)
      expect(testobj.old_file).to eq(loc_1['file'])
    end

    it 'should return nil when information is not present for a change' do
      testobj = described_class.new(chg_1)
      expect(testobj.old_file).to be_nil
    end
  end

  describe '#old_line' do
    it 'should return nil for an addition' do
      testobj = described_class.new(add_2)
      expect(testobj.old_line).to be_nil
    end

    it 'should return the line for a removal' do
      testobj = described_class.new(del_2)
      expect(testobj.old_line).to eq(loc_1['line'])
    end

    it 'should return nil when information is not present for a removal' do
      testobj = described_class.new(del_1)
      expect(testobj.old_line).to be_nil
    end

    it 'should return the line for a change' do
      testobj = described_class.new(chg_2)
      expect(testobj.old_line).to eq(loc_1['line'])
    end

    it 'should return nil when information is not present for a change' do
      testobj = described_class.new(chg_1)
      expect(testobj.old_line).to be_nil
    end
  end

  describe '#new_file' do
    it 'should return nil for a removal' do
      testobj = described_class.new(del_2)
      expect(testobj.new_file).to be_nil
    end

    it 'should return the filename for an addition' do
      testobj = described_class.new(add_2)
      expect(testobj.new_file).to eq(loc_2['file'])
    end

    it 'should return nil when information is not present for an addition' do
      testobj = described_class.new(add_1)
      expect(testobj.new_file).to be_nil
    end

    it 'should return the filename for a change' do
      testobj = described_class.new(chg_2)
      expect(testobj.new_file).to eq(loc_2['file'])
    end

    it 'should return nil when information is not present for a change' do
      testobj = described_class.new(chg_1)
      expect(testobj.new_file).to be_nil
    end
  end

  describe '#new_line' do
    it 'should return nil for a removal' do
      testobj = described_class.new(del_2)
      expect(testobj.new_line).to be_nil
    end

    it 'should return the line for an addition' do
      testobj = described_class.new(add_2)
      expect(testobj.new_line).to eq(loc_2['line'])
    end

    it 'should return nil when information is not present for an addition' do
      testobj = described_class.new(add_1)
      expect(testobj.new_line).to be_nil
    end

    it 'should return the line for a change' do
      testobj = described_class.new(chg_2)
      expect(testobj.new_line).to eq(loc_2['line'])
    end

    it 'should return nil when information is not present for a change' do
      testobj = described_class.new(chg_1)
      expect(testobj.new_line).to be_nil
    end
  end

  describe '#to_h' do
    it 'should return a hash with the expected keys and values' do
      methods = %w(diff_type type title structure old_value new_value old_line new_line old_file new_file)
      testobj = described_class.new(chg_2)
      result = testobj.to_h
      methods.each do |method_name|
        method = method_name.to_sym
        expect(result.key?(method)).to eq(true)
        expect(result[method]).to eq(testobj.send(method))
      end
    end
  end

  describe '#inspect' do
    it 'should return a string' do
      testobj = described_class.new(chg_2)
      expect(testobj.inspect).to be_a_kind_of(String)
    end
  end

  describe '#to_s' do
    it 'should return a string' do
      testobj = described_class.new(chg_2)
      expect(testobj.to_s).to be_a_kind_of(String)
    end
  end

  describe '#initialize' do
    it 'should raise ArgumentError if called with a non-array' do
      expect { described_class.new('foo') }.to raise_error(ArgumentError)
    end
  end
end
