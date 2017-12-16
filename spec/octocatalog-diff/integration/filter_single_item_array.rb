# frozen_string_literal: true

require_relative 'integration_helper'

describe 'filter single-item arrays' do
  context 'with default behavior' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_catalog_old: 'filter-single-item-array-1.json',
        spec_catalog_new: 'filter-single-item-array-2.json'
      )
      @diffs = OctocatalogDiff::Spec.remove_file_and_line(@result[:diffs])
    end

    it 'should succeed' do
      expect(@result[:exitcode]).not_to eq(-1), "Internal error: #{@result[:exception]}\n#{@result[:logs]}"
      expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
    end

    it 'should contain the correct number of diffs' do
      expect(@diffs.size).to eq(4), @diffs.inspect
    end

    it 'should contain a diff of a string to a single-item array' do
      expect(@diffs).to include(
        ['~', "File\f/tmp/amazing\fparameters\fnotify", 'Service[foo]', ['Service[foo]']]
      )
    end

    it 'should contain a diff of an array whose size has changed' do
      expect(@diffs).to include(
        ['~', "File\f/tmp/foobar\fparameters\fnotify", 'Service[foobar]', ['Service[fizzbuzz]', 'Service[foobar]']]
      )
    end

    it 'should contain a diff of an array whose elements have changed' do
      expect(@diffs).to include(
        ['!', "File\f/tmp/awesome\fparameters\fnotify", ['Service[bar]', 'Service[foo]'], ['Service[baz]', 'Service[foo]']]
      )
    end

    it 'should contain a diff of an array that has been added' do
      expect(@diffs).to include(
        ['!', "File\f/tmp/fizzbuzz\fparameters\fnotify", nil, ['Service[fizzbuzz]']]
      )
    end
  end
end
