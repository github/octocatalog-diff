# frozen_string_literal: true

require_relative 'integration_helper'

OctocatalogDiff::Spec.require_path('/util/catalogs')

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

      it 'should raise OctocatalogDiff::Errors::CatalogError' do
        expect(@result.exception).to be_a_kind_of(OctocatalogDiff::Errors::CatalogError)
      end

      it 'should fail because ::bar could not be located' do
        expect(@result.exception.message).to match(/Could not find class (::)?bar for rspec-node.github.net/)
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
            '--hiera-config', 'config/hiera.yaml',
            '--hiera-path-strip', '/var/lib/puppet', '--no-parallel'
          ]
        )
      end

      it 'should exit without error' do
        expect(@result.exitcode).to eq(0), OctocatalogDiff::Integration.format_exception(@result)
        expect(@result.exception).to be_nil, OctocatalogDiff::Integration.format_exception(@result)
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
        expect(@result.logs).to match(/WARN -- : --create-symlinks is ignored unless --preserve-environments is used/)
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

      it 'should exit with error status due modules in production environment not being found' do
        expect(@result.exitcode).to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
        expect(@result.exception).to be_a_kind_of(Errno::ENOENT)
        expect(@result.exception.message).to match(/No such file or directory - Environment directory/)
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
            '--create-symlinks', 'modules,site'
          ]
        )
      end

      it 'should error on missing environment' do
        expect(@result.exitcode).to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
        expect(@result.exception).to be_a_kind_of(Errno::ENOENT)
        expect(@result.exception.message).to match(%r{Environment directory .+/environments/fluffy does not exist})
      end
    end

    context 'and --create-symlinks set' do
      context 'to modules,site' do
        before(:all) do
          @result = OctocatalogDiff::Integration.integration(
            spec_fact_file: 'facts.yaml',
            spec_repo: 'preserve-environments',
            argv: [
              '-n', 'rspec-node.github.net',
              '--preserve-environments',
              '--from-environment', 'one',
              '--to-environment', 'two',
              '--create-symlinks', 'modules,site',
              '--hiera-config', 'hiera.yaml',
              '--hiera-path-strip', '/var/lib/puppet'
            ]
          )
        end

        it 'should exit without error' do
          expect(@result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
          expect(@result.exception).to be_nil, OctocatalogDiff::Integration.format_exception(@result)
          expect(@result.diffs.any?).to eq(true), OctocatalogDiff::Integration.format_exception(@result)
        end

        it 'should display proper diffs' do
          resource = {
            diff_type: '~',
            type: 'File',
            title: '/tmp/bar',
            structure: %w(parameters content),
            old_value: 'one',
            new_value: 'two'
          }
          expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)

          resource = {
            diff_type: '~',
            type: 'File',
            title: '/tmp/bar',
            structure: %w(parameters owner),
            old_value: 'one',
            new_value: 'two'
          }
          expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)

          resource = {
            diff_type: '~',
            type: 'File',
            title: '/tmp/foo',
            structure: %w(parameters content),
            old_value: 'one',
            new_value: 'two'
          }
          expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)

          resource = {
            diff_type: '~',
            type: 'File',
            title: '/tmp/sitetest',
            structure: %w(parameters content),
            old_value: 'one',
            new_value: 'two'
          }
          expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], resource)).to eq(true)
        end

        it 'should handle hieradata properly' do
          h = @result.diffs.select { |x| x[1] == "File\f/tmp/bar-param.txt\fparameters\fcontent" }
          expect(h.size).to eq(1), h.inspect
          expect(h.first[2]).to eq('one Value from one/hieradata/common.yaml')
          expect(h.first[3]).to eq('two Value from two/hieradata/common.yaml')
        end
      end

      context 'to modules' do
        before(:all) do
          @result = OctocatalogDiff::Integration.integration(
            spec_fact_file: 'facts.yaml',
            spec_repo: 'preserve-environments',
            argv: [
              '-n', 'rspec-node.github.net', '--no-parallel',
              '--retry-failed-catalog', '0',
              '--preserve-environments',
              '--from-environment', 'one',
              '--to-environment', 'two',
              '--create-symlinks', 'modules'
            ]
          )
        end

        it 'should error on missing site directory' do
          expect(@result.exitcode).to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
          expect(@result.exception).to be_a_kind_of(OctocatalogDiff::Errors::CatalogError)
          expect(@result.exception.message).to match(/Could not find class (::)?sitetest/)
        end
      end

      context 'to site' do
        before(:all) do
          @result = OctocatalogDiff::Integration.integration(
            spec_fact_file: 'facts.yaml',
            spec_repo: 'preserve-environments',
            argv: [
              '-n', 'rspec-node.github.net', '--no-parallel',
              '--retry-failed-catalog', '0',
              '--preserve-environments',
              '--from-environment', 'one',
              '--to-environment', 'two',
              '--create-symlinks', 'site'
            ]
          )
        end

        it 'should error on missing module' do
          expect(@result.exitcode).to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
          expect(@result.exception).to be_a_kind_of(OctocatalogDiff::Errors::CatalogError)
          expect(@result.exception.message).to match(/Could not find class (::)?foo/)
        end
      end

      context 'to missing value' do
        before(:all) do
          @result = OctocatalogDiff::Integration.integration(
            spec_fact_file: 'facts.yaml',
            spec_repo: 'preserve-environments',
            argv: [
              '-n', 'rspec-node.github.net', '--no-parallel',
              '--retry-failed-catalog', '0',
              '--preserve-environments',
              '--from-environment', 'one',
              '--to-environment', 'two',
              '--create-symlinks', 'modules,fluffy'
            ]
          )
        end

        it 'should raise exception due to missing symlink request' do
          expect(@result.exitcode).to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
          expect(@result.exception).to be_a_kind_of(Errno::ENOENT)
          expect(@result.exception.message).to match(%r{Specified directory .+/preserve-environments/fluffy doesn't exist})
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
              '--to-create-symlinks', 'modules,site',
              '--from-create-symlinks', 'site,modules'
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
              '--from-create-symlinks', 'modules,site'
            ]
          )
        end

        it 'should error on missing site directory' do
          expect(@result.exitcode).to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
          expect(@result.exception).to be_a_kind_of(OctocatalogDiff::Errors::CatalogError)
          expect(@result.exception.message).to match(/Could not find class (::)?sitetest/)
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

      it 'should error on missing site directory' do
        expect(@result.exitcode).to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
        expect(@result.exception).to be_a_kind_of(OctocatalogDiff::Errors::CatalogError)
        expect(@result.exception.message).to match(/Could not find class (::)?sitetest/)
      end
    end
  end
end
