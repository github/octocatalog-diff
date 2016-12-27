# frozen_string_literal: true

require_relative 'integration_helper'

OctocatalogDiff::Spec.require_path('/catalog')

describe 'preserve environments integration' do
  context 'without --preserve-environments set' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_fact_file: 'facts.yaml',
        spec_repo: 'preserve-environments',
        argv: [
          '-n', 'rspec-node.github.net'
        ]
      )
    end

    it 'should exit with error status' do
      expect(@result.exitcode).to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
    end

    it 'should raise OctocatalogDiff::CatalogDiff::Cli::Catalogs::CatalogError' do
      expect(@result.exception).to be_a_kind_of(OctocatalogDiff::CatalogDiff::Cli::Catalogs::CatalogError)
    end

    it 'should fail because ::bar could not be located' do
      expect(@result.exception.message).to match(/Could not find class ::bar for rspec-node.github.net/)
    end
  end

  context 'with --preserve-environments set' do
    context 'and --environment set to non-existent value' do
      before(:all) do
        @result = OctocatalogDiff::Integration.integration(
          spec_fact_file: 'facts.yaml',
          spec_repo: 'preserve-environments',
          argv: [
            '-n', 'rspec-node.github.net',
            '--preserve-environments',
            '--from-environment', 'one',
            '--to-environment', 'fluffy',
            '--create-symlinks', 'modules,sitetest'
          ]
        )
      end

      it 'should error on missing environment' do
        expect(@result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
        expect(@result.exception).to be_nil, OctocatalogDiff::Integration.format_exception(@result)
      end
    end

    context 'and --create-symlinks set' do
      context 'to modules,sitetest' do
        before(:all) do
          @result = OctocatalogDiff::Integration.integration(
            spec_fact_file: 'facts.yaml',
            spec_repo: 'preserve-environments',
            argv: [
              '-n', 'rspec-node.github.net',
              '--preserve-environments',
              '--from-environment', 'one',
              '--to-environment', 'two',
              '--create-symlinks', 'modules,sitetest'
            ]
          )
        end

        it 'should exit without error' do
          expect(@result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
          expect(@result.exception).to be_nil, OctocatalogDiff::Integration.format_exception(@result)
        end
      end

      context 'to modules' do
        before(:all) do
          @result = OctocatalogDiff::Integration.integration(
            spec_fact_file: 'facts.yaml',
            spec_repo: 'preserve-environments',
            argv: [
              '-n', 'rspec-node.github.net',
              '--preserve-environments',
              '--from-environment', 'one',
              '--to-environment', 'two',
              '--create-symlinks', 'modules'
            ]
          )
        end

        it 'should error on missing sitetest' do
          expect(@result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
          expect(@result.exception).to be_nil, OctocatalogDiff::Integration.format_exception(@result)
        end
      end

      context 'to sitetest' do
        before(:all) do
          @result = OctocatalogDiff::Integration.integration(
            spec_fact_file: 'facts.yaml',
            spec_repo: 'preserve-environments',
            argv: [
              '-n', 'rspec-node.github.net',
              '--preserve-environments',
              '--from-environment', 'one',
              '--to-environment', 'two',
              '--create-symlinks', 'sitetest'
            ]
          )
        end

        it 'should error on missing module' do
          expect(@result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
          expect(@result.exception).to be_nil, OctocatalogDiff::Integration.format_exception(@result)
        end
      end

      context 'to missing value' do
        before(:all) do
          @result = OctocatalogDiff::Integration.integration(
            spec_fact_file: 'facts.yaml',
            spec_repo: 'preserve-environments',
            argv: [
              '-n', 'rspec-node.github.net',
              '--preserve-environments',
              '--from-environment', 'one',
              '--to-environment', 'two',
              '--create-symlinks', 'modules,fluffy'
            ]
          )
        end

        it 'should error on missing symlink' do
          expect(@result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
          expect(@result.exception).to be_nil, OctocatalogDiff::Integration.format_exception(@result)
        end
      end
    end

    context 'and --to-create-symlinks, --from-create-symlinks set' do
      context 'to modules,sitetest' do
        before(:all) do
          @result = OctocatalogDiff::Integration.integration(
            spec_fact_file: 'facts.yaml',
            spec_repo: 'preserve-environments',
            argv: [
              '-n', 'rspec-node.github.net',
              '--preserve-environments',
              '--from-environment', 'one',
              '--to-environment', 'two',
              '--to-create-symlinks', 'modules,sitetest',
              '--from-create-symlinks', 'sitetest,modules'
            ]
          )
        end

        it 'should succeed' do
          expect(@result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
          expect(@result.exception).to be_nil, OctocatalogDiff::Integration.format_exception(@result)
        end
      end

      context 'to different values' do
        before(:all) do
          @result = OctocatalogDiff::Integration.integration(
            spec_fact_file: 'facts.yaml',
            spec_repo: 'preserve-environments',
            argv: [
              '-n', 'rspec-node.github.net',
              '--preserve-environments',
              '--from-environment', 'one',
              '--to-environment', 'two',
              '--to-create-symlinks', 'modules',
              '--from-create-symlinks', 'modules,sitetest'
            ]
          )
        end

        it 'should error to-catalog missing sitetest' do
          expect(@result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
          expect(@result.exception).to be_nil, OctocatalogDiff::Integration.format_exception(@result)
        end
      end
    end

    context 'and --create-symlinks unset' do
      before(:all) do
        @result = OctocatalogDiff::Integration.integration(
          spec_fact_file: 'facts.yaml',
          spec_repo: 'preserve-environments',
          argv: [
            '-n', 'rspec-node.github.net',
            '--preserve-environments',
            '--from-environment', 'one',
            '--to-environment', 'two'
          ]
        )
      end

      it 'should error on missing module' do
        expect(@result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
        expect(@result.exception).to be_nil, OctocatalogDiff::Integration.format_exception(@result)
      end
    end
  end
end
