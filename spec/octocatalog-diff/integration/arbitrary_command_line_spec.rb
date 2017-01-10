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
      resource = { diff_type: '+', type: 'File', title: '/tmp/environment-foo-site' }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
    end

    it 'should contain resource from environments/foo modules/foo' do
      resource = { diff_type: '+', type: 'File', title: '/tmp/environment-foo-module' }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
    end

    it 'should not contain resource from environments/production' do
      resource = { diff_type: '+', type: 'File', title: '/tmp/environment-production-site' }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(false)
    end

    it 'should not contain resource from main modules/foo' do
      resource = { diff_type: '+', type: 'File', title: '/tmp/foo-module' }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(false)
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
      resource = { diff_type: '+', type: 'File', title: '/tmp/environment-foo-site' }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
    end

    it 'should contain resource from environments/foo modules/foo only in to catalog' do
      resource = { diff_type: '+', type: 'File', title: '/tmp/environment-foo-module' }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
    end

    it 'should contain resource from environments/production only in from catalog' do
      resource = { diff_type: '+', type: 'File', title: '/tmp/environment-production-site' }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(false)
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
      resource = { diff_type: '+', type: 'File', title: '/tmp/environment-foo-site' }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
    end

    it 'should contain resource from environments/foo modules/foo' do
      resource = { diff_type: '+', type: 'File', title: '/tmp/environment-foo-module' }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
    end

    it 'should not contain resource from environments/production' do
      resource = { diff_type: '+', type: 'File', title: '/tmp/environment-production-site' }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(false)
    end

    it 'should not contain resource from main modules/foo' do
      resource = { diff_type: '+', type: 'File', title: '/tmp/foo-module' }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(false)
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
      resource = { diff_type: '+', type: 'File', title: '/tmp/environment-foo-site' }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
    end

    it 'should not contain resource from environments/foo modules/foo' do
      resource = { diff_type: '+', type: 'File', title: '/tmp/environment-foo-module' }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(false)
    end

    it 'should not contain resource from environments/production' do
      resource = { diff_type: '+', type: 'File', title: '/tmp/environment-production-site' }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(false)
    end

    it 'should contain resource from main modules/foo' do
      resource = { diff_type: '+', type: 'File', title: '/tmp/foo-module' }
      expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
    end
  end
end
