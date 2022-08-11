# frozen_string_literal: true

require_relative 'integration_helper'

describe 'equivalent array no datatypes filter integration' do
  context 'with default behavior' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_catalog_old: 'filter-equivalent-array-1.json',
        spec_catalog_new: 'filter-equivalent-array-2.json'
      )
    end

    it 'should succeed' do
      expect(@result[:exitcode]).not_to eq(-1), "Internal error: #{@result[:exception]}\n#{@result[:logs]}"
      expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
    end

    it 'should not suppress equivalent-but-for-data-type arrays' do
      diffs = OctocatalogDiff::Spec.remove_file_and_line(@result[:diffs])
      expect(diffs.size).to eq(3), diffs.inspect
      expect(diffs[0][1..3]).to eq(["Exec\frun-my-command 1\fparameters\freturns", '0'.inspect, 0])
      expect(diffs[1][1..3]).to eq(["Exec\frun-my-command 2\fparameters\freturns", %w[0 1], [0, 1]])
      expect(diffs[2][1..3]).to eq(["Exec\frun-my-command 3\fparameters\freturns", %w[0 1 2], [0, 1, 2, 3]])
    end
  end

  context 'with equivalent array no datatypes filter engaged' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_catalog_old: 'filter-equivalent-array-1.json',
        spec_catalog_new: 'filter-equivalent-array-2.json',
        argv: ['--filters', 'EquivalentArrayNoDatatypes']
      )
    end

    it 'should succeed' do
      expect(@result[:exitcode]).not_to eq(-1), "Internal error: #{@result[:exception]}\n#{@result[:logs]}"
      expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
    end

    it 'should suppress equivalent-but-for-data-type arrays' do
      diffs = OctocatalogDiff::Spec.remove_file_and_line(@result[:diffs])
      expect(diffs.size).to eq(2), diffs.inspect
      # '0' => 0 is not suppressed because it's not an array
      expect(diffs[0][1..3]).to eq(["Exec\frun-my-command 1\fparameters\freturns", '0'.inspect, 0])
      # %w[0 1] => [0, 1] is suppressed
      # %w[0 1 2] => [0, 1, 2, 3] is not suppressed because it's not equivalent
      expect(diffs[1][1..3]).to eq(["Exec\frun-my-command 3\fparameters\freturns", %w[0 1 2], [0, 1, 2, 3]])
    end
  end
end
