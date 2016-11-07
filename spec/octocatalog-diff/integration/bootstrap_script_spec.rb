# Integration tests around specifying a bootstrap script to confirm:
# - Bootstrap script failing => failure of octocatalog-diff process
# - Bootstrap debugging printed with --debug-bootstrap enabled
# - Bootstrap debugging printed when bootstrap script fails

require 'fileutils'
require_relative 'integration_helper'

describe 'bootstrap script integration test' do
  context 'with --bootstrap-current not specified' do
    it 'should not run the bootstrap script' do
      result = OctocatalogDiff::Integration.integration(
        spec_catalog_old: 'catalog-empty.json',
        spec_fact_file: 'facts.yaml',
        argv: [
          '--basedir', OctocatalogDiff::Spec.fixture_path('repos/bootstrap'),
          '--bootstrap-script', 'config/bootstrap.sh',
          '--to', '.'
        ]
      )
      expect(result[:exitcode]).to eq(-1)
      expect(result[:exception].message).to match(/Could not find class (::)?test for rspec-node.xyz.github.net/)
    end
  end

  context 'when a bootstrap script fails' do
    before(:all) do
      @repo_dir = Dir.mktmpdir
      FileUtils.cp_r OctocatalogDiff::Spec.fixture_path('repos/bootstrap'), @repo_dir

      @result = OctocatalogDiff::Integration.integration(
        spec_catalog_old: 'catalog-empty.json',
        spec_fact_file: 'facts.yaml',
        argv: [
          '--basedir', File.join(@repo_dir, 'bootstrap'),
          '--bootstrap-current',
          '--bootstrap-script', 'config/broken-bootstrap.sh',
          '--no-parallel',
          '--to', '.'
        ]
      )
    end

    after(:all) do
      OctocatalogDiff::Spec.clean_up_tmpdir(@repo_dir)
    end

    it 'should exit with error status' do
      expect(@result[:exitcode]).to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
    end

    it 'should print error from bootstrap failing' do
      expect(@result[:exception].message).to match(/Catalog for 'to' \(.\) failed to compile with.+::BootstrapError/)
      expect(@result[:exception].message).to match(/OctocatalogDiff::CatalogUtil::Bootstrap::BootstrapError/)
      expect(@result[:exception].message).not_to match(/Could not find class (::)?test/)
    end

    it 'should print debugging output from bootstrap script' do
      expect(@result[:logs]).to match(/Bootstrap: Fail, stdout/)
      expect(@result[:logs]).to match(/Bootstrap: Fail, stderr/)
    end
  end

  context 'when a bootstrap script succeeds' do
    context 'with bootstrap debugging enabled' do
      before(:all) do
        @repo_dir = Dir.mktmpdir
        FileUtils.cp_r OctocatalogDiff::Spec.fixture_path('repos/bootstrap'), @repo_dir

        @result = OctocatalogDiff::Integration.integration(
          spec_catalog_old: 'catalog-empty.json',
          spec_fact_file: 'facts.yaml',
          argv: [
            '--basedir', File.join(@repo_dir, 'bootstrap'),
            '--bootstrap-current',
            '--bootstrap-script', 'config/bootstrap.sh',
            '--debug-bootstrap',
            '--no-parallel',
            '--to', '.'
          ]
        )
      end

      after(:all) do
        OctocatalogDiff::Spec.clean_up_tmpdir(@repo_dir)
      end

      it 'should exit with success status' do
        expect(@result[:exitcode]).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
      end

      it 'should contain the added resource' do
        answer = [
          '+',
          "File\f/tmp/foo",
          {
            'type' => 'File',
            'title' => '/tmp/foo',
            'tags' => %w(class file test),
            'exported' => false,
            'parameters' => { 'content' => "Test 123\n" }
          }
        ]
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(@result[:diffs], answer)).to eq(true)
      end

      it 'should print debugging output from bootstrap script' do
        expect(@result[:logs]).to match(/Bootstrap: Hello, stdout/)
        expect(@result[:logs]).to match(/Bootstrap: Hello, stderr/)
      end
    end

    context 'with bootstrap debugging disabled' do
      before(:all) do
        @repo_dir = Dir.mktmpdir
        FileUtils.cp_r OctocatalogDiff::Spec.fixture_path('repos/bootstrap'), @repo_dir

        @result = OctocatalogDiff::Integration.integration(
          spec_catalog_old: 'catalog-empty.json',
          spec_fact_file: 'facts.yaml',
          argv: [
            '--basedir', File.join(@repo_dir, 'bootstrap'),
            '--bootstrap-current',
            '--bootstrap-script', 'config/bootstrap.sh',
            '--no-parallel',
            '--to', '.'
          ]
        )
      end

      after(:all) do
        OctocatalogDiff::Spec.clean_up_tmpdir(@repo_dir)
      end

      it 'should exit with success status' do
        expect(@result[:exitcode]).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
      end

      it 'should contain the added resource' do
        answer = [
          '+',
          "File\f/tmp/foo",
          {
            'type' => 'File',
            'title' => '/tmp/foo',
            'tags' => %w(class file test),
            'exported' => false,
            'parameters' => { 'content' => "Test 123\n" }
          }
        ]
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(@result[:diffs], answer)).to eq(true)
      end

      it 'should not print debugging output from bootstrap script' do
        expect(@result[:logs]).not_to match(/Bootstrap:.*/)
      end
    end
  end
end
