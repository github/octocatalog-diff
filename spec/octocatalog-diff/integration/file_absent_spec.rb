# frozen_string_literal: true

require_relative 'integration_helper'

describe 'file absent integration' do
  context 'with default behavior' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_catalog_old: 'catalog-test-file-v4.json',
        spec_catalog_new: 'catalog-test-file-absent.json'
      )
    end

    it 'should succeed' do
      expect(@result[:exitcode]).not_to eq(-1), "Internal error: #{@result[:exception]}\n#{@result[:logs]}"
      expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
    end

    it 'should suppress attribute changes when target file is ensure=>absent' do
      diffs = OctocatalogDiff::Spec.remove_file_and_line(@result[:diffs])
      expect(diffs.size).to eq(1), diffs.inspect
      diff = diffs.first
      expect(diff[1..3]).to eq(["File\f/tmp/foo\fparameters\fensure", nil, 'absent'])
    end

    it 'should print the proper debug log messages' do
      expect(@result[:logs]).to match(/Entering filter_diffs_for_absent_files with 4 diffs/)
      expect(@result[:logs]).to match(%r{Removing file=/tmp/foo parameter=group for absent file})
      expect(@result[:logs]).to match(%r{Removing file=/tmp/foo parameter=owner for absent file})
      expect(@result[:logs]).to match(%r{Removing file=/tmp/foo parameter=mode for absent file})
      expect(@result[:logs]).to match(/Exiting filter_diffs_for_absent_files with 1 diffs/)
    end
  end

  context 'with file absent suppression disabled' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_catalog_old: 'catalog-test-file-v4.json',
        spec_catalog_new: 'catalog-test-file-absent.json',
        argv: ['--no-suppress-absent-file-details']
      )
    end

    it 'should succeed' do
      expect(@result[:exitcode]).not_to eq(-1), "Internal error: #{@result[:exception]}\n#{@result[:logs]}"
      expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
    end

    it 'should not suppress attribute changes when target file is ensure=>absent' do
      diffs = OctocatalogDiff::Spec.remove_file_and_line(@result[:diffs])
      expect(diffs.size).to eq(4)
      expect(diffs[0][1..3]).to eq(["File\f/tmp/foo\fparameters\fgroup", 'root', 'git'])
      expect(diffs[1][1..3]).to eq(["File\f/tmp/foo\fparameters\fmode", '0440', '0755'])
      expect(diffs[2][1..3]).to eq(["File\f/tmp/foo\fparameters\fowner", 'root', 'git'])
      expect(diffs[3][1..3]).to eq(["File\f/tmp/foo\fparameters\fensure", nil, 'absent'])
    end

    it 'should print the proper debug log messages' do
      expect(@result[:logs]).not_to match(/Entering filter_diffs_for_absent_files/)
    end
  end
end
