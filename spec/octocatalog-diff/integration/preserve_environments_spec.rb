# frozen_string_literal: true

require_relative 'integration_helper'

OctocatalogDiff::Spec.require_path('/catalog-diff/cli/catalogs')

describe 'preserve environments integration' do
  context 'without --preserve-environments set' do
    context 'without --environment set' do
      before(:all) do
        @result = OctocatalogDiff::Integration.integration(
          spec_fact_file: 'facts.yaml',
          spec_repo: 'preserve-environments',
          argv: [
            '-n', 'rspec-node.github.net',
            '--retry-failed-catalog', '0'
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

    context 'with --environment set' do
      before(:all) do
        @result = OctocatalogDiff::Integration.integration(
          spec_fact_file: 'facts.yaml',
          spec_repo_old: 'default',
          argv: [
            '-n', 'rspec-node.github.net',
            '--environment', 'asdfgh',
            '--to-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/default-catalog-v4.json'),
            '--hiera-config', 'environments/production/config/hiera.yaml',
            '--hiera-path-strip', '/var/lib/puppet', '--no-parallel'
          ]
        )
      end

      it 'should exit without error' do
        expect(@result.exitcode).to eq(0), OctocatalogDiff::Integration.format_exception(@result)
        expect(@result.exception).to be_nil, OctocatalogDiff::Integration.format_exception(@result)
      end

      it 'should log warning about --environment being useless in this context' do
        expect(@result.logs).to match(/WARN -- : --environment is ignored unless --preserve-environment is used/)
      end
    end

    context 'with --create-symlinks set' do
      before(:all) do
        @result = OctocatalogDiff::Integration.integration(
          spec_fact_file: 'facts.yaml',
          spec_repo_old: 'default',
          argv: [
            '-n', 'rspec-node.github.net',
            '--create-symlinks', 'asdfgh,asldfk',
            '--to-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/default-catalog-v4.json'),
            '--hiera-config', 'environments/production/config/hiera.yaml',
            '--hiera-path-strip', '/var/lib/puppet', '--no-parallel'
          ]
        )
      end

      it 'should exit without error' do
        expect(@result.exitcode).to eq(0), OctocatalogDiff::Integration.format_exception(@result)
        expect(@result.exception).to be_nil, OctocatalogDiff::Integration.format_exception(@result)
      end

      it 'should log warning about --create-symlinks being useless in this context' do
        expect(@result.logs).to match(/WARN -- : --create-symlinks is ignored unless --preserve-environment is used/)
      end
    end
  end

  context 'with --preserve-environments set' do
    context 'and --environment, --create-symlinks unset' do
      before(:all) do
        @result = OctocatalogDiff::Integration.integration(
          spec_fact_file: 'facts.yaml',
          spec_repo: 'preserve-environments',
          argv: [
            '-n', 'rspec-node.github.net',
            '--retry-failed-catalog', '0',
            '--preserve-environments'
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

    context 'and --environment set to non-existent value' do
      before(:all) do
        @result = OctocatalogDiff::Integration.integration(
          spec_fact_file: 'facts.yaml',
          spec_repo: 'preserve-environments',
          argv: [
            '-n', 'rspec-node.github.net',
            '--retry-failed-catalog', '0',
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
              '--retry-failed-catalog', '0',
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
              '--retry-failed-catalog', '0',
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
              '--retry-failed-catalog', '0',
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
              '--retry-failed-catalog', '0',
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
            '--retry-failed-catalog', '0',
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
