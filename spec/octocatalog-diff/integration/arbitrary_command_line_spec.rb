# frozen_string_literal: true

require_relative 'integration_helper'

OctocatalogDiff::Spec.require_path('/catalog')

describe 'passes command line options to puppet' do
  context 'with one argument passed' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_repo_new: 'arbitrary-command-line',
        spec_fact_file: 'facts.yaml',
        argv: [
          '-n', 'rspec-node.github.net', '--no-parallel', '--preserve-environments',
          '--from-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/default-catalog-v4.json'),
          '--command-line', '--environment=foo'
        ]
      )
    end

    it 'should compile without exceptions' do
      expect(@result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
      expect(@result.exception).to be_nil
    end

    it 'should contain resource from environments/foo site.pp' do
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(
               @result.diffs,
               ['+', "File\f/tmp/environment-foo-site"]
      )).to eq(true)
    end

    it 'should contain resource from environments/foo modules/foo' do
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(
               @result.diffs,
               ['+', "File\f/tmp/environment-foo-module"]
      )).to eq(true)
    end

    it 'should not contain resource from environments/production' do
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(
               @result.diffs,
               ['+', "File\f/tmp/environment-production-site"]
      )).to eq(false)
    end

    it 'should not contain resource from main modules/foo' do
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(
               @result.diffs,
               ['+', "File\f/tmp/foo-module"]
      )).to eq(false)
    end
  end

  context 'with argument passed only to one catalog' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_repo_new: 'arbitrary-command-line',
        spec_fact_file: 'facts.yaml',
        argv: [
          '-n', 'rspec-node.github.net', '--no-parallel', '--preserve-environments',
          '-f', '.',
          '--to-command-line', '--environment=foo'
        ]
      )
    end

    it 'should compile without exceptions' do
      expect(@result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
      expect(@result.exception).to be_nil
    end

    it 'should contain resource from environments/foo site.pp only in to catalog' do
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(
               @result.diffs,
               ['+', "File\f/tmp/environment-foo-site"]
      )).to eq(true)
    end

    it 'should contain resource from environments/foo modules/foo only in to catalog' do
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(
               @result.diffs,
               ['+', "File\f/tmp/environment-foo-module"]
      )).to eq(true)
    end

    it 'should contain resource from environments/production only in from catalog' do
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(
               @result.diffs,
               ['-', "File\f/tmp/environment-production-site"]
      )).to eq(true)
    end
  end

  context 'with override of an argument' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_repo_new: 'arbitrary-command-line',
        spec_fact_file: 'facts.yaml',
        argv: [
          '-n', 'rspec-node.github.net', '--no-parallel', '--preserve-environments',
          '--from-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/default-catalog-v4.json'),
          '--command-line', '--environment=foo',
          '--environment', 'production'
        ]
      )
    end

    it 'should compile without exceptions' do
      expect(@result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
      expect(@result.exception).to be_nil
    end

    it 'should contain resource from environments/foo site.pp' do
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(
               @result.diffs,
               ['+', "File\f/tmp/environment-foo-site"]
      )).to eq(true)
    end

    it 'should contain resource from environments/foo modules/foo' do
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(
               @result.diffs,
               ['+', "File\f/tmp/environment-foo-module"]
      )).to eq(true)
    end

    it 'should not contain resource from environments/production' do
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(
               @result.diffs,
               ['+', "File\f/tmp/environment-production-site"]
      )).to eq(false)
    end

    it 'should not contain resource from main modules/foo' do
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(
               @result.diffs,
               ['+', "File\f/tmp/foo-module"]
      )).to eq(false)
    end
  end

  context 'with multiple arguments' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_repo_new: 'arbitrary-command-line',
        spec_fact_file: 'facts.yaml',
        argv: [
          '-n', 'rspec-node.github.net', '--no-parallel', '--preserve-environments',
          '--from-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/default-catalog-v4.json'),
          '--command-line', '--environment=foo',
          '--command-line', '--modulepath=modules'
        ]
      )
    end

    it 'should compile without exceptions' do
      expect(@result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
      expect(@result.exception).to be_nil
    end

    it 'should contain resource from environments/foo site.pp' do
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(
               @result.diffs,
               ['+', "File\f/tmp/environment-foo-site"]
      )).to eq(true)
    end

    it 'should not contain resource from environments/foo modules/foo' do
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(
               @result.diffs,
               ['+', "File\f/tmp/environment-foo-module"]
      )).to eq(false)
    end

    it 'should not contain resource from environments/production' do
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(
               @result.diffs,
               ['+', "File\f/tmp/environment-production-site"]
      )).to eq(false)
    end

    it 'should contain resource from main modules/foo' do
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(
               @result.diffs,
               ['+', "File\f/tmp/foo-module"]
      )).to eq(true)
    end
  end
end
