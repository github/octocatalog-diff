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

  context 'with option auto-disabled' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration_cli(
        [
          '--fact-file', OctocatalogDiff::Spec.fixture_path('facts/facts.yaml'),
          '--catalog-only',
          '-n', 'rspec-node.github.net',
          '--compare-file-text',
          '--basedir', OctocatalogDiff::Spec.fixture_path('repos/convert-resources/new'),
          '--puppet-binary', OctocatalogDiff::Spec::PUPPET_BINARY,
          '--debug'
        ]
      )
    end

    it 'should compile the catalog' do
      expect(@result[:exitcode]).not_to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
      expect(@result[:exitcode]).to eq(0), "Runtime error: #{@result[:logs]}"
    end

    it 'should indicate that the option was disabled' do
      expect(@result[:stderr]).to match(/Disabling --compare-file-text; not supported by OctocatalogDiff::Catalog::Noop/)
    end

    it 'should not have converted resources in the catalog' do
      catalog = OctocatalogDiff::Catalog::JSON.new(json: @result[:stdout])
      resource = catalog.resource(type: 'File', title: '/tmp/foo2')
      expect(resource).to be_a_kind_of(Hash)
      expect(resource['parameters']).to eq('source' => 'puppet:///modules/test/foo-old')
    end
  end

  context 'with option force-enabled' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration_cli(
        [
          '--fact-file', OctocatalogDiff::Spec.fixture_path('facts/facts.yaml'),
          '--catalog-only',
          '-n', 'rspec-node.github.net',
          '--compare-file-text=force',
          '--basedir', OctocatalogDiff::Spec.fixture_path('repos/convert-resources/new'),
          '--puppet-binary', OctocatalogDiff::Spec::PUPPET_BINARY,
          '--debug'
        ]
      )
    end

    it 'should compile the catalog' do
      expect(@result[:exitcode]).not_to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
      expect(@result[:exitcode]).to eq(0), "Runtime error: #{@result[:logs]}"
    end

    it 'should indicate that the option was force-enabled' do
      rexp = /--compare-file-text is force-enabled even though it is not supported by OctocatalogDiff::Catalog::Noop/
      expect(@result[:stderr]).to match(rexp)
    end

    it 'should have converted resources in the catalog' do
      catalog = OctocatalogDiff::Catalog::JSON.new(json: @result[:stdout])
      resource = catalog.resource(type: 'File', title: '/tmp/foo2')
      expect(resource).to be_a_kind_of(Hash)
      expect(resource['parameters']).to eq('content' => "content of foo-old\n")
    end
  end

  context 'with option force-enabled and broken reference in catalog-only' do
    it 'should fail' do
      result = OctocatalogDiff::Integration.integration_cli(
        [
          '--fact-file', OctocatalogDiff::Spec.fixture_path('facts/facts.yaml'),
          '--catalog-only',
          '-n', 'rspec-node.github.net',
          '--compare-file-text=force',
          '--basedir', OctocatalogDiff::Spec.fixture_path('repos/convert-resources/broken'),
          '--puppet-binary', OctocatalogDiff::Spec::PUPPET_BINARY,
          '--debug'
        ]
      )
      expect(result[:exitcode]).to eq(1)
      expect(result[:stderr]).to match(%r{Unable to resolve source=>'puppet:///modules/test/foo-new' in File\[/tmp/foo1\] \(modules/test/manifests/init.pp:\d+\)}) # rubocop:disable Metrics/LineLength
    end
  end

  context 'with option force-enabled to "from" and broken reference in catalog-only' do
    it 'should not fail' do
      result = OctocatalogDiff::Integration.integration_cli(
        [
          '--fact-file', OctocatalogDiff::Spec.fixture_path('facts/facts.yaml'),
          '--catalog-only',
          '-n', 'rspec-node.github.net',
          '--compare-file-text=soft',
          '--basedir', OctocatalogDiff::Spec.fixture_path('repos/convert-resources/broken'),
          '--puppet-binary', OctocatalogDiff::Spec::PUPPET_BINARY,
          '--debug'
        ]
      )
      expect(result[:exitcode]).to eq(0), OctocatalogDiff::Integration.format_exception(result)
      catalog = OctocatalogDiff::Catalog::JSON.new(json: result[:stdout])
      resource = catalog.resource(type: 'File', title: '/tmp/foo1')
      expect(resource).to be_a_kind_of(Hash)
      expect(resource['parameters']).to be_a_kind_of(Hash)
      expect(resource['parameters']['source']).to eq('puppet:///modules/test/foo-new')
      expect(resource['parameters']['content']).to be nil
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
      expect(result[:exitcode]).to eq(-1), OctocatalogDiff::Integration.format_exception(result)
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
