require 'json'

require_relative '../spec_helper'

require OctocatalogDiff::Spec.require_path('/catalog')
require OctocatalogDiff::Spec.require_path('/catalog/computed')
require OctocatalogDiff::Spec.require_path('/catalog-util/builddir')

describe OctocatalogDiff::Catalog::Computed do
  context 'bootstrapping in the current directory' do
    before(:all) do
      @repo_dir = Dir.mktmpdir
      FileUtils.cp_r OctocatalogDiff::Spec.fixture_path('repos/bootstrap'), @repo_dir

      @node = 'rspec-node.github.net'
      catalog_opts = {
        node: @node,
        puppet_binary: OctocatalogDiff::Spec::PUPPET_BINARY,
        basedir: File.join(@repo_dir, 'bootstrap'),
        fact_file: OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml'),
        branch: '.',
        bootstrap_current: true,
        debug_bootstrap: true,
        bootstrap_script: 'config/bootstrap.sh'
      }
      @catalog = OctocatalogDiff::Catalog::Computed.new(catalog_opts)
      logger, @logger_str = OctocatalogDiff::Spec.setup_logger
      @catalog.build(logger)
    end

    after(:all) do
      OctocatalogDiff::Spec.clean_up_tmpdir(@repo_dir)
    end

    describe '#bootstrap' do
      it 'should result in a successful compilation' do
        expect(@catalog.catalog).to be_a_kind_of(Hash), @catalog.inspect
      end

      it 'should log debug messages' do
        expect(@logger_str.string).to match(/Bootstrap: Hello, stdout/)
        expect(@logger_str.string).to match(/Bootstrap: Hello, stderr/)
      end
    end
  end

  context 'compiling a catalog' do
    context 'with a working catalog' do
      before(:all) do
        @node = 'rspec-node.github.net'
        catalog_opts = {
          node: @node,
          puppet_binary: OctocatalogDiff::Spec::PUPPET_BINARY,
          basedir: OctocatalogDiff::Spec.fixture_path('repos/default'),
          fact_file: OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml'),
          hiera_config: OctocatalogDiff::Spec.fixture_path('configs/hiera.yaml'),
          hiera_path_strip: '/var/lib/puppet',
          branch: '.'
        }
        @catalog = OctocatalogDiff::Catalog::Computed.new(catalog_opts)
        logger, @logger_str = OctocatalogDiff::Spec.setup_logger
        @catalog.build(logger)
      end

      describe '#build' do
        it 'should print correct log messages' do
          expect(@logger_str.string).to match(%r{Symlinked.*environments/production ->.*/repos/default})
          expect(@logger_str.string).to match(/Installed hiera.yaml from/)
          expect(@logger_str.string).to match(/Installed fact file at/)
          expect(@logger_str.string).to match(/puppet master --compile rspec-node.github.net/)
          expect(@logger_str.string).to match(/Catalog succeeded on try 1/)
        end
      end

      describe '#catalog' do
        it 'should have the correct structure for a working catalog' do
          parse_result = @catalog.catalog
          expect(parse_result).to be_a_kind_of(Hash)
          if parse_result.key?('document_type')
            # Puppet 3.x catalog
            %w(data metadata).each { |key| expect(parse_result).to include(key) }
            expect(parse_result['document_type']).to eq('Catalog')
            expect(parse_result['data']).to be_a_kind_of(Hash)
            expect(parse_result['data']['resources']).to be_a_kind_of(Array)
          else
            # Puppet 4.x catalog
            expect(parse_result.key?('resources')).to eq(true)
            expect(parse_result['resources']).to be_a_kind_of(Array)
          end
        end
      end

      describe '#catalog_json' do
        it 'should have the correct structure for a working catalog' do
          result = @catalog.catalog_json
          expect(result).to be_a_kind_of(String)
          parse_result = JSON.parse(result)
          if parse_result.key?('document_type')
            # Puppet 3.x catalog
            %w(data metadata).each { |key| expect(parse_result).to include(key) }
            expect(parse_result['document_type']).to eq('Catalog')
            expect(parse_result['data']).to be_a_kind_of(Hash)
            expect(parse_result['data']['resources']).to be_a_kind_of(Array)
          else
            # Puppet 4.x catalog
            expect(parse_result.key?('resources')).to eq(true)
            expect(parse_result['resources']).to be_a_kind_of(Array)
          end
        end
      end

      describe '#compilation_dir' do
        it 'should be set if compilation succeeded' do
          result = @catalog.compilation_dir
          # Since this is a temporary directory handled by the class, it's difficult to test for
          # a specific value here. However, this directory should exist and have the right content,
          # so we will use that to test.
          expect(File.directory?(result)).to eq(true)
          expect(File.file?(File.join(result, 'hiera.yaml'))).to eq(true)
        end
      end

      describe '#error_message' do
        it 'should be nil if catalog compilation succeeded' do
          result = @catalog.error_message
          expect(result).to eq(nil)
        end
      end
    end

    context 'with a failing catalog' do
      before(:all) do
        @node = 'rspec-node.github.net'
        catalog_opts = {
          node: @node,
          puppet_binary: OctocatalogDiff::Spec::PUPPET_BINARY,
          basedir: OctocatalogDiff::Spec.fixture_path('repos/failing-catalog'),
          fact_file: OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml'),
          branch: '.'
        }
        @catalog = OctocatalogDiff::Catalog::Computed.new(catalog_opts)
        logger, @logger_str = OctocatalogDiff::Spec.setup_logger
        @catalog.build(logger)
      end

      describe '#build' do
        it 'should have the correct log messages' do
          expect(@logger_str.string).to match(%r{Symlinked.*environments/production ->.*/repos/failing-catalog})
          expect(@logger_str.string).to match(/Installed fact file at/)
          expect(@logger_str.string).to match(/puppet master --compile rspec-node.github.net/)
          expect(@logger_str.string).to match(/Catalog failed on try 1/)
        end
      end

      describe '#catalog' do
        it 'should be nil if the catalog was in error' do
          result = @catalog.catalog
          expect(result).to eq(nil)
        end
      end

      describe '#catalog_json' do
        it 'should be nil if the catalog was in error' do
          result = @catalog.catalog_json
          expect(result).to eq(nil)
        end
      end

      describe '#error_message' do
        it 'should contain a string if catalog was in error' do
          result = @catalog.error_message
          expect(result).to be_a_kind_of(String)
          expect(result).to match(/Error:.*Could not find class (::)?this::module::does::not::exist/)
        end
      end
    end
  end

  context 'testing compile mechanisms' do
    describe '#build_catalog' do
      before(:all) do
        @temp_repo_dir = OctocatalogDiff::Spec.shell_script_for_envvar_testing('catalog')
      end

      after(:all) do
        FileUtils.rm_r(@temp_repo_dir) unless @temp_repo_dir.nil? || !Dir.exist?(@temp_repo_dir)
      end

      # Catalog object currently builds with the order of command line options such that environment
      # is last. The spec helper script looks at the last argument. Therefore set 'environment' to the
      # name of the environment variable you with to obtain.
      it 'should pass the HOME directory' do
        opts = {
          basedir: @temp_repo_dir,
          puppet_binary: File.join(@temp_repo_dir, 'script', 'catalog'),
          puppet_version: '3.8',
          puppet_command: File.join(@temp_repo_dir, 'script', 'catalog') + ' HOME',
          fact_file: OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml'),
          node: 'foonode',
          branch: '.'
        }
        catalog = OctocatalogDiff::Catalog::Computed.new(opts.merge(environment: 'HOME'))
        catalog.build
        expect(catalog.error_message.strip).to eq(ENV['HOME'])
      end

      it 'should clean the environment' do
        ENV['THIS_IS_IN_MY_ENV'] = 'BLAH'
        opts = {
          basedir: @temp_repo_dir,
          puppet_binary: File.join(@temp_repo_dir, 'script', 'catalog'),
          puppet_version: '3.8',
          puppet_command: File.join(@temp_repo_dir, 'script', 'catalog') + ' THIS_IS_IN_MY_ENV',
          fact_file: OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml'),
          node: 'foonode',
          branch: '.'
        }
        catalog = OctocatalogDiff::Catalog::Computed.new(opts.merge(environment: 'THIS_IS_IN_MY_ENV'))
        catalog.build
        expect(catalog.error_message.strip).to eq('')
      end

      it 'should pass the environment variables in pass_env_vars' do
        ENV['THIS_IS_IN_MY_ENV'] = 'BLAH'
        opts = {
          basedir: @temp_repo_dir,
          puppet_binary: File.join(@temp_repo_dir, 'script', 'catalog'),
          puppet_version: '3.8',
          pass_env_vars: ['THIS_IS_IN_MY_ENV'],
          puppet_command: File.join(@temp_repo_dir, 'script', 'catalog') + ' THIS_IS_IN_MY_ENV',
          fact_file: OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml'),
          node: 'foonode',
          branch: '.'
        }
        catalog = OctocatalogDiff::Catalog::Computed.new(opts.merge(environment: 'THIS_IS_IN_MY_ENV'))
        catalog.build
        expect(catalog.error_message.strip).to eq('BLAH')
      end
    end

    describe '#puppet_version' do
      context 'with working Puppet version' do
        before(:all) do
          @temp_puppet = Tempfile.new('puppet')
          @temp_puppet.write "#!/bin/bash\n"
          @temp_puppet.write "echo '3.8.7'\n"
          @temp_puppet.close
          FileUtils.chmod 0o755, @temp_puppet.path
        end

        after(:all) do
          @temp_puppet.unlink
        end

        it 'should return a puppet version upon success' do
          opts = {
            basedir: '/',
            node: 'foonode',
            puppet_binary: @temp_puppet.path,
            puppet_command: @temp_puppet.path,
            fact_file: OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml'),
            branch: '.'
          }
          catalog = OctocatalogDiff::Catalog::Computed.new(opts)
          catalog.build
          expect(catalog.puppet_version).to eq('3.8.7')
        end
      end

      context 'with failing Puppet version' do
        before(:all) do
          @temp_puppet = Tempfile.new('puppet')
          @temp_puppet.write "#!/bin/bash\n"
          @temp_puppet.write "echo 1>&2 'something failed horribly'\n"
          @temp_puppet.write "exit 1\n"
          @temp_puppet.close
          FileUtils.chmod 0o755, @temp_puppet.path
        end

        after(:all) do
          @temp_puppet.unlink
        end

        it 'should raise an error if the version number is empty' do
          opts = {
            basedir: '/',
            node: 'foonode',
            puppet_binary: @temp_puppet.path,
            puppet_command: @temp_puppet.path,
            fact_file: OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml'),
            branch: '.'
          }
          expect { OctocatalogDiff::Catalog::Computed.new(opts).build }
            .to raise_error(RuntimeError, /Unable to determine Puppet version/)
        end
      end
    end

    it 'should raise an error if the puppet binary is nil' do
      opts = {
        basedir: '/',
        node: 'foonode',
        puppet_command: '/alsdfklafjasfkljafjafkjsdflaksfjasdfjadsfjadsf',
        fact_file: OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml'),
        branch: '.'
      }
      expect { OctocatalogDiff::Catalog::Computed.new(opts).build }.to raise_error(ArgumentError)
    end

    it 'should raise an error if the puppet binary does not exist' do
      opts = {
        basedir: '/',
        node: 'foonode',
        puppet_binary: '/alsdfklafjasfkljafjafkjsdflaksfjasdfjadsfjadsf',
        puppet_command: '/alsdfklafjasfkljafjafkjsdflaksfjasdfjadsfjadsf',
        fact_file: OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml'),
        branch: '.'
      }
      expect { OctocatalogDiff::Catalog::Computed.new(opts).build }
        .to raise_error(Errno::ENOENT)
    end
  end

  describe '#bootstrap' do
    it 'should raise error if directory is provided that does not exist' do
      opts = { node: 'foo', branch: 'bar', bootstrapped_dir: OctocatalogDiff::Spec.fixture_path('null') }
      obj = OctocatalogDiff::Catalog::Computed.new(opts)
      logger, _logger_str = OctocatalogDiff::Spec.setup_logger
      expect { obj.send(:bootstrap, logger) }.to raise_error(Errno::ENOENT, /Invalid dir /)
    end

    it 'should use an existing directory if provided' do
      begin
        dir = OctocatalogDiff::Spec.extract_fixture_repo('simple-repo')
        opts = {
          node: 'rspec-node-github.net',
          branch: 'this-branch-is-invalid-on-purpose',
          bootstrapped_dir: File.join(dir, 'git-repo'),
          basedir: File.join(dir, 'git-repo'),
          fact_file: OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml')
        }
        obj = OctocatalogDiff::Catalog::Computed.new(opts)
        logger, logger_str = OctocatalogDiff::Spec.setup_logger
        expect { obj.send(:bootstrap, logger) }.not_to raise_error
        expect(logger_str.string).to match(/Symlinked/)
        expect(logger_str.string).to match(%r{Installed fact file at.*/var/yaml/facts/rspec-node-github.net.yaml})
      ensure
        OctocatalogDiff::Spec.clean_up_tmpdir(dir)
      end
    end
  end

  describe '#cleanup_checkout_dir' do
    it 'should remove a directory if one exists' do
      opts = { node: 'foo', branch: 'bar', bootstrapped_dir: OctocatalogDiff::Spec.fixture_path('null') }
      obj = OctocatalogDiff::Catalog::Computed.new(opts)
      logger, _logger_str = OctocatalogDiff::Spec.setup_logger
      begin
        dir = Dir.mktmpdir
        expect(File.directory?(dir)).to eq(true)
        obj.send(:cleanup_checkout_dir, dir, logger)
        expect(File.directory?(dir)).to eq(false)
      ensure
        OctocatalogDiff::Spec.clean_up_tmpdir(dir)
      end
    end

    it 'should not error if a directory does not exist' do
      opts = { node: 'foo', branch: 'bar', bootstrapped_dir: OctocatalogDiff::Spec.fixture_path('null') }
      obj = OctocatalogDiff::Catalog::Computed.new(opts)
      logger, _logger_str = OctocatalogDiff::Spec.setup_logger
      dir = OctocatalogDiff::Spec.fixture_path('null')
      expect { obj.send(:cleanup_checkout_dir, dir, logger) }.not_to raise_error
    end
  end
end
