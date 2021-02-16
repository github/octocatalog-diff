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

  context 'with broken reference in to-catalog' do
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
      expect(result[:exception].message).to match(%r{\AUnable to resolve source=>'puppet:///modules/test/foo-new' in File\[/tmp/foo1\] \(modules/test/manifests/init.pp:\d+\)\z}) # rubocop:disable Metrics/LineLength
    end

    context 'with --convert-file-resources-ignore-tags' do
      before(:all) do
        @result = OctocatalogDiff::Integration.integration(
          spec_fact_file: 'facts.yaml',
          spec_repo_old: 'convert-resources/old',
          spec_repo_new: 'convert-resources/broken',
          argv: [
            '-n', 'rspec-node.github.net',
            '--compare-file-text',
            '--compare-file-text-ignore-tags', '_convert_file_resources_foo1_'
          ]
        )
      end

      it 'should compile the catalog' do
        expect(@result[:exitcode]).not_to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
        expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
        expect(@result[:diffs]).to be_a_kind_of(Array)
      end

      it 'should leave /tmp/foo1 parameters:source alone in the new catalog' do
        resource = {
          diff_type: '!',
          type: 'File',
          title: '/tmp/foo1',
          structure: %w(parameters source),
          old_value: nil,
          new_value: 'puppet:///modules/test/foo-new'
        }
        expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
      end
    end
  end

  context 'with broken reference in from-catalog' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_fact_file: 'facts.yaml',
        spec_repo_old: 'convert-resources/broken',
        spec_repo_new: 'convert-resources/old',
        argv: [
          '-n', 'rspec-node.github.net',
          '--compare-file-text'
        ]
      )
    end

    it 'should succeed' do
      expect(@result[:exitcode]).not_to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
      expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
      expect(@result[:diffs]).to be_a_kind_of(Array)
    end

    it 'should leave /tmp/foo1 parameters:source alone in the old catalog' do
      resource = {
        diff_type: '!',
        type: 'File',
        title: '/tmp/foo1',
        structure: %w(parameters source),
        old_value: 'puppet:///modules/test/foo-new',
        new_value: nil
      }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
    end

    it 'should populate /tmp/foo1 parameters:content in the new catalog' do
      resource = {
        diff_type: '!',
        type: 'File',
        title: '/tmp/foo1',
        structure: %w(parameters content),
        old_value: nil,
        new_value: "content of foo-old\n"
      }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
    end
  end

  context 'when an array is used as the source and the first file is found' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_fact_file: 'facts.yaml',
        spec_repo_old: 'convert-resources/old',
        spec_repo_new: 'convert-resources/new',
        argv: [
          '-n', 'rspec-node.github.net',
          '--compare-file-text',
          '--fact-override', 'test_class=array1'
        ]
      )
    end

    it 'should compile the catalog' do
      expect(@result[:exitcode]).not_to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
      expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
      expect(@result[:diffs]).to be_a_kind_of(Array)
    end

    it 'should contain the correct number of diffs' do
      expect(@result[:diffs].size).to eq(1)
    end

    it 'should contain a change to the file' do
      resource = {
        diff_type: '~',
        type: 'File',
        title: '/tmp/foo',
        structure: %w(parameters content),
        old_value: "content of foo-old\n",
        new_value: "content of foo-new\n"
      }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
    end
  end

  context 'when an array is used as the source and a later file is found' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_fact_file: 'facts.yaml',
        spec_repo_old: 'convert-resources/old',
        spec_repo_new: 'convert-resources/new',
        argv: [
          '-n', 'rspec-node.github.net',
          '--compare-file-text',
          '--fact-override', 'test_class=array2'
        ]
      )
    end

    it 'should compile the catalog' do
      expect(@result[:exitcode]).not_to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
      expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
      expect(@result[:diffs]).to be_a_kind_of(Array)
    end

    it 'should contain the correct number of diffs' do
      expect(@result[:diffs].size).to eq(1)
    end

    it 'should contain a change to the file' do
      resource = {
        diff_type: '~',
        type: 'File',
        title: '/tmp/foo',
        structure: %w(parameters content),
        old_value: "content of foo-old\n",
        new_value: "content of foo-new\n"
      }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
    end
  end

  context 'when an array is used as the source and no file is found' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_fact_file: 'facts.yaml',
        spec_repo_old: 'convert-resources/old',
        spec_repo_new: 'convert-resources/new',
        argv: [
          '-n', 'rspec-node.github.net',
          '--compare-file-text',
          '--fact-override', 'test_class=array3'
        ]
      )
    end

    it 'should fail' do
      expect(@result[:exitcode]).to eq(-1)
      expect(@result[:exception]).to be_a_kind_of(OctocatalogDiff::Errors::CatalogError)
      expect(@result[:exception].message).to match(%r{\AUnable to resolve source=>'\["puppet:///modules/test/foo-bar", "puppet:///modules/test/foo-baz"\]' in File\[/tmp/foo\] \(modules/test/manifests/array3.pp:\d+\)\z}) # rubocop:disable Metrics/LineLength
    end
  end
end
