# frozen_string_literal: true

require_relative 'integration_helper'

describe 'convert file resources' do
  context 'with option enabled' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_fact_file: 'facts.yaml',
        spec_repo_old: 'convert-resources/old',
        spec_repo_new: 'convert-resources/new',
        argv: [
          '-n', 'rspec-node.github.net',
          '--compare-file-text'
        ]
      )
    end

    it 'should compile the catalog' do
      expect(@result[:exitcode]).not_to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
      expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
      expect(@result[:diffs]).to be_a_kind_of(Array)
    end

    it 'should contain the correct number of diffs' do
      expect(@result[:diffs].size).to eq(3), @result[:diffs].inspect
    end

    it 'should contain /tmp/foo1' do
      resource = {
        diff_type: '~',
        type: 'File',
        title: '/tmp/foo1',
        structure: %w(parameters content),
        old_value: "content of foo-old\n",
        new_value: "content of foo-new\n"
      }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
    end

    it 'should contain /tmp/binary1' do
      resource = {
        diff_type: '~',
        type: 'File',
        title: '/tmp/binary1',
        structure: %w(parameters content),
        old_value: '{md5}e0897d525d5d600a037622b62fc99a4c',
        new_value: '{md5}97918b387001eb04ae7cb20b13e07f43'
      }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
    end

    it 'should contain /tmp/bar2' do
      resource = {
        diff_type: '~',
        type: 'File',
        title: '/tmp/bar2',
        structure: %w(parameters content),
        old_value: "content of bar\n",
        new_value: "content of new-bar\n"
      }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
    end
  end

  context 'with option disabled' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_fact_file: 'facts.yaml',
        spec_repo_old: 'convert-resources/old',
        spec_repo_new: 'convert-resources/new',
        argv: [
          '-n', 'rspec-node.github.net',
          '--no-compare-file-text'
        ]
      )
    end

    it 'should compile the catalog' do
      expect(@result[:exitcode]).not_to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
      expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
      expect(@result[:diffs]).to be_a_kind_of(Array)
    end

    it 'should contain the correct number of diffs' do
      expect(@result[:diffs].size).to eq(8)
    end

    it 'should contain /tmp/binary1' do
      resource = {
        diff_type: '~',
        type: 'File',
        title: '/tmp/binary1',
        structure: %w(parameters source),
        old_value: 'puppet:///modules/test/binary-old',
        new_value: 'puppet:///modules/test/binary-new'
      }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
    end

    it 'should contain /tmp/binary3' do
      resource = {
        diff_type: '~',
        type: 'File',
        title: '/tmp/binary3',
        structure: %w(parameters source),
        old_value: 'puppet:///modules/test/binary-old',
        new_value: 'puppet:///modules/test/binary-old2'
      }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
    end

    it 'should contain /tmp/foo1' do
      resource = {
        diff_type: '~',
        type: 'File',
        title: '/tmp/foo1',
        structure: %w(parameters source),
        old_value: 'puppet:///modules/test/foo-old',
        new_value: 'puppet:///modules/test/foo-new'
      }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
    end

    it 'should contain /tmp/bar content' do
      resource = {
        diff_type: '!',
        type: 'File',
        title: '/tmp/bar',
        structure: %w(parameters content),
        old_value: nil,
        new_value: "content of bar\n"
      }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
    end

    it 'should contain /tmp/bar source' do
      resource = {
        diff_type: '!',
        type: 'File',
        title: '/tmp/bar',
        structure: %w(parameters source),
        old_value: 'puppet:///modules/test/bar-old',
        new_value: nil
      }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
    end
  end

  context 'with broken repo' do
    it 'should fail' do
      result = OctocatalogDiff::Integration.integration(
        spec_fact_file: 'facts.yaml',
        spec_repo_old: 'convert-resources/old',
        spec_repo_new: 'convert-resources/broken',
        argv: [
          '-n', 'rspec-node.github.net',
          '--compare-file-text'
        ]
      )
      expect(result[:exitcode]).to eq(-1)
      expect(result[:exception]).to be_a_kind_of(OctocatalogDiff::Errors::CatalogError)
      expect(result[:exception].message).to match(/Errno::ENOENT/)
      expect(result[:exception].message).to match(%r{Unable to resolve 'puppet:///modules/test/foo-new'})
    end
  end
end
