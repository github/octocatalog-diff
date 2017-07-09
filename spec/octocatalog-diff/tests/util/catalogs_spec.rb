# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../mocks/puppetdb'

require OctocatalogDiff::Spec.require_path('/catalog')
require OctocatalogDiff::Spec.require_path('/errors')
require OctocatalogDiff::Spec.require_path('/facts')
require OctocatalogDiff::Spec.require_path('/util/catalogs')

require 'json'
require 'open3'
require 'shellwords'
require 'yaml'

# If a catalog cannot be compiled due to missing dependencies, this object will be
# substituted instead so that the tests don't throw syntax errors.
class BadCatalog
  attr_reader :catalog, :catalog_json, :resources, :error_message

  def initialize(message = 'Catalog not compiled due to missing dependencies')
    @error_message = message
    @catalog = nil
    @catalog_json = nil
    @resources = []
  end

  def resource(_options = {})
    nil
  end

  def valid?
    false
  end
end

# Here begin the tests
describe OctocatalogDiff::Util::Catalogs do
  before(:all) do
    # These are the default options for all tests.
    @default_options = {
      from_env: 'master',
      from_puppet_binary: OctocatalogDiff::Spec::PUPPET_BINARY,
      node: 'rspec-node.github.net',
      to_env: 'test-branch',
      to_puppet_binary: OctocatalogDiff::Spec::PUPPET_BINARY,
      parallel: false,
      fact_file: OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml')
    }

    # Make sure 'git' is available and works. This is used to check out branches of the
    # git repository into temporary directories.
    @git_stderr = OctocatalogDiff::Spec.test_command('git --version')
    @has_git = @git_stderr.nil?

    # Make sure 'tar' is available and works. This is used to extract the tarball with
    # the sample git repository.
    @tar_stderr = OctocatalogDiff::Spec.test_command('tar --version')
    @has_tar = @tar_stderr.nil?

    # If tar is available, extract the fixture tarball into the expected location.
    @git_checkout_dir = OctocatalogDiff::Spec.extract_fixture_repo('simple-repo')
    @default_options[:basedir] = File.join(@git_checkout_dir, 'git-repo') unless @git_checkout_dir.nil?

    # Make sure 'bash' is available and works. This is used to run the bootstrap script.
    @bash_stderr = OctocatalogDiff::Spec.test_command('bash --version')
    @has_bash = @bash_stderr.nil?
  end

  after(:all) do
    OctocatalogDiff::Spec.clean_up_tmpdir(@git_checkout_dir)
  end

  context 'rspec environment setup' do
    it 'should have working git' do
      pending "git not installed or not working: #{@git_stderr}" unless @has_git
      expect(@has_git).to eq(true)
    end

    it 'should have working tar' do
      pending "tar not installed or not working: #{@tar_stderr}" unless @has_tar
      expect(@has_tar).to eq(true)
    end

    it 'should have working bash' do
      pending "bash not installed or not working: #{@bash_stderr}" unless @has_bash
      expect(@has_bash).to eq(true)
    end
  end

  describe '#bootstrap_then_exit' do
    it 'should error when neither directory is specified' do
      options = @default_options.merge(from_env: 'master')
      logger, logger_string = OctocatalogDiff::Spec.setup_logger
      testobj = OctocatalogDiff::Util::Catalogs.new(options, logger)
      expect { testobj.bootstrap_then_exit }.to raise_error(OctocatalogDiff::Errors::BootstrapError)
      expect(logger_string.string).to match(%r{Specify one or more of --bootstrapped-from-dir / --bootstrapped-to-dir})
    end

    it 'should error when the supplied directory is not a git repo' do
      # This test will throw the desired exception even if 'tar' did not work.
      # Therefore, no 'pending' based on @has_tar is needed here.
      begin
        tmpdir1 = Dir.mktmpdir
        tmpdir2 = Dir.mktmpdir
        options = @default_options.merge(basedir: tmpdir2, bootstrapped_from_dir: tmpdir1, from_env: 'asdfasdfasdf')
        logger, logger_string = OctocatalogDiff::Spec.setup_logger
        testobj = OctocatalogDiff::Util::Catalogs.new(options, logger)
        expect { testobj.bootstrap_then_exit }.to raise_error(OctocatalogDiff::Errors::BootstrapError)
        expect(logger_string.string).to match(/DEBUG .+ Failed bootstrap from_dir/)
      ensure
        OctocatalogDiff::Spec.clean_up_tmpdir(tmpdir1)
        OctocatalogDiff::Spec.clean_up_tmpdir(tmpdir2)
      end
    end

    it 'should error when an invalid git branch is provided' do
      # This test will throw the desired exception if 'git' is unavailable in the path.
      # Therefore, no 'pending' based on @has_git is needed here.
      begin
        tmpdir1 = Dir.mktmpdir
        options = @default_options.merge(bootstrapped_from_dir: tmpdir1, from_env: 'asdfasdfasdf')
        logger, logger_string = OctocatalogDiff::Spec.setup_logger
        testobj = OctocatalogDiff::Util::Catalogs.new(options, logger)
        expect { testobj.bootstrap_then_exit }.to raise_error(OctocatalogDiff::Errors::BootstrapError)
        expect(logger_string.string).to match(/DEBUG .+ Failed bootstrap from_dir/)
      ensure
        OctocatalogDiff::Spec.clean_up_tmpdir(tmpdir1)
      end
    end

    context 'bootstrapping two specified directories' do
      before(:all) do
        @dir1 = Dir.mktmpdir
        @dir2 = Dir.mktmpdir
        if @has_git && @has_tar && @has_bash
          options = @default_options.merge(bootstrap_script: 'script/bootstrap.sh',
                                           bootstrapped_from_dir: @dir1,
                                           bootstrapped_to_dir: @dir2)
          logger, logger_string = OctocatalogDiff::Spec.setup_logger
          testobj = OctocatalogDiff::Util::Catalogs.new(options, logger)
          path_save = ENV['PATH']
          begin
            @bootstrap_error_message = nil
            ENV['PATH'] = '/usr/sbin:/sbin:/usr/bin:/bin:/usr/local/bin:/usr/local/sbin'
            testobj.bootstrap_then_exit
          rescue OctocatalogDiff::Errors::BootstrapError => exc
            @bootstrap_error_message = "BootstrapError #{exc}: #{logger_string.string}"
          ensure
            ENV['PATH'] = path_save
          end
        else
          @bootstrap_error_message = 'Skipped test because git, tar, and bash are not all available'
        end
      end

      after(:all) do
        OctocatalogDiff::Spec.clean_up_tmpdir(@dir1)
        OctocatalogDiff::Spec.clean_up_tmpdir(@dir2)
      end

      it 'should succeed' do
        pending 'bash, git, and/or tar are required for most tests' unless @has_git && @has_tar && @has_bash
        expect(@bootstrap_error_message).to be(nil)
      end

      # The bootstrap is supposed to run 'script/bootstrap.sh' which in turn creates the file
      # 'bootstrap_result.yaml' in the result directory.
      it 'should contain bootstrap_result.yaml in dir1' do
        pending 'bash, git, and/or tar are required for most tests' unless @has_git && @has_tar && @has_bash
        bootstrap_result = File.join(@dir1, 'bootstrap_result.yaml')
        expect(File.file?(bootstrap_result)).to eq(true)
        yaml_content = YAML.load_file(bootstrap_result)
        expect(yaml_content).to be_a_kind_of(Hash)
        expect(yaml_content['env::path']).to eq('/usr/sbin:/sbin:/usr/bin:/bin:/usr/local/bin:/usr/local/sbin')
        expect(yaml_content['env::pwd']).to eq(@dir1)
      end

      # The bootstrap is supposed to run 'script/bootstrap.sh' which in turn creates the file
      # 'bootstrap_result.yaml' in the result directory.
      it 'should contain bootstrap_result.yaml in dir2' do
        pending 'bash, git, and/or tar are required for most tests' unless @has_git && @has_tar && @has_bash
        bootstrap_result = File.join(@dir2, 'bootstrap_result.yaml')
        expect(File.file?(bootstrap_result)).to eq(true)
        yaml_content = YAML.load_file(bootstrap_result)
        expect(yaml_content).to be_a_kind_of(Hash)
        expect(yaml_content['env::path']).to eq('/usr/sbin:/sbin:/usr/bin:/bin:/usr/local/bin:/usr/local/sbin')
        expect(yaml_content['env::pwd']).to eq(@dir2)
      end
    end
  end

  context 'with an invalid enc' do
    describe '#catalogs' do
      it 'should fail to compile the catalog' do
        pending 'bash, git, and/or tar are required for most tests' unless @has_tar
        options = @default_options.merge(enc: 'asdkfjlfjkalksdfads')
        logger, _logger_string = OctocatalogDiff::Spec.setup_logger
        testobj = OctocatalogDiff::Util::Catalogs.new(options, logger)
        re = %r{ENC.*/asdkfjlfjkalksdfads wasn't found}
        expect { testobj.catalogs }.to raise_error(Errno::ENOENT, re)
      end
    end
  end

  context 'with an invalid hiera config' do
    describe '#catalogs' do
      it 'should fail to compile the catalog' do
        pending 'bash, git, and/or tar are required for most tests' unless @has_tar
        options = @default_options.merge(hiera_config: 'asdkfjlfjkalksdfads')
        logger, _logger_string = OctocatalogDiff::Spec.setup_logger
        testobj = OctocatalogDiff::Util::Catalogs.new(options, logger)
        re = %r{hiera.yaml.*/asdkfjlfjkalksdfads\) wasn't found}
        expect { testobj.catalogs }.to raise_error(Errno::ENOENT, re)
      end
    end
  end

  context 'existing catalogs' do
    describe '#catalogs' do
      # If we pass through the catalogs, they should be returned without any processing.
      # When catalogs are passed through, none of the debugging logs are triggered, so
      # verifying that the file content matches and that there is no debugging will confirm
      # that no extra processing has occurred.
      it 'should pass through without compiling' do
        options = @default_options.merge(
          from_catalog: OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog.json'),
          to_catalog: OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog-2.json')
        )
        logger, logger_string = OctocatalogDiff::Spec.setup_logger
        testobj = OctocatalogDiff::Util::Catalogs.new(options, logger)
        result = testobj.catalogs

        test_val = result[:from].catalog_json.gsub(/\s+/, '')
        answer_val = File.read(options[:from_catalog]).gsub(/\s+/, '')
        expect(test_val).to eq(answer_val)

        test_val = result[:to].catalog_json.gsub(/\s+/, '')
        answer_val = File.read(options[:to_catalog]).gsub(/\s+/, '')
        expect(test_val).to eq(answer_val)

        expect(logger_string.string).to match(/Catalog for test-branch will be built with OctocatalogDiff::Catalog::JSON/)
        expect(logger_string.string).to match(/Catalog for master will be built with OctocatalogDiff::Catalog::JSON/)
        resource = result[:from].resource(type: 'Stage', title: 'main')
        expect(resource).to be_a_kind_of(Hash)
        expect(resource['parameters']).to eq('name' => 'main')
      end
    end
  end

  describe '#build_catalog_parallelizer' do
    it 'should select noop backend if incoming catalog is a minus sign' do
      options = { from_catalog: '-', to_catalog: '-', from_branch: 'foo', to_branch: 'bar' }
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      testobj = OctocatalogDiff::Util::Catalogs.new(options, logger)
      result = testobj.send(:build_catalog_parallelizer)
      expect(logger_str.string).to match(/Initialized OctocatalogDiff::Catalog::Noop for from-catalog/)
      expect(logger_str.string).to match(/Initialized OctocatalogDiff::Catalog::Noop for to-catalog/)
      expect(logger_str.string).to match(/Catalog for foo will be built with OctocatalogDiff::Catalog::Noop/)
      expect(logger_str.string).to match(/Catalog for bar will be built with OctocatalogDiff::Catalog::Noop/)
      expect(result).to be_a_kind_of(Hash)
      expect(result[:from]).to be_a_kind_of(OctocatalogDiff::Catalog)
      expect(result[:to]).to be_a_kind_of(OctocatalogDiff::Catalog)
      expect(result[:from].builder.to_s).to eq('OctocatalogDiff::Catalog::Noop')
      expect(result[:to].builder.to_s).to eq('OctocatalogDiff::Catalog::Noop')
    end

    it 'should disable --compare-file-text when using a backend that does not support it' do
      options = {
        from_puppetdb: true,
        to_catalog: OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog.json'),
        compare_file_text: true,
        node: 'tiny-catalog-2-puppetdb',
        basedir: '/asdflkj/asdflkj/asldfjk',
        from_branch: 'foo'
      }
      allow(OctocatalogDiff::PuppetDB).to receive(:new) do |*_arg|
        OctocatalogDiff::Mocks::PuppetDB.new
      end
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      testobj = OctocatalogDiff::Util::Catalogs.new(options, logger)
      result = testobj.send(:build_catalog_parallelizer)
      expect(logger_str.string).to match(/Initialized OctocatalogDiff::Catalog::JSON for to-catalog/)
      expect(logger_str.string).to match(/Initialized OctocatalogDiff::Catalog::PuppetDB for from-catalog/)
      expect(logger_str.string).to match(/Disabling --compare-file-text; not supported by OctocatalogDiff::Catalog::PuppetDB/)
      expect(result).to be_a_kind_of(Hash)
      expect(result[:from]).to be_a_kind_of(OctocatalogDiff::Catalog)
      expect(result[:to]).to be_a_kind_of(OctocatalogDiff::Catalog)
      expect(result[:from].builder.to_s).to eq('OctocatalogDiff::Catalog::PuppetDB')
      expect(result[:to].builder.to_s).to eq('OctocatalogDiff::Catalog::JSON')
    end

    it 'should raise OctocatalogDiff::Errors::CatalogError if either catalog fails' do
      options = {
        to_catalog: OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog.json'),
        from_fact_file: OctocatalogDiff::Spec.fixture_path('facts/facts.yaml'),
        bootstrapped_from_dir: OctocatalogDiff::Spec.fixture_path('repos/failing-catalog'),
        node: 'tiny-catalog-2-puppetdb',
        from_branch: 'foo',
        from_env: 'foo-env',
        puppet_binary: OctocatalogDiff::Spec::PUPPET_BINARY
      }
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      testobj = OctocatalogDiff::Util::Catalogs.new(options, logger)
      expect do
        testobj.send(:build_catalog_parallelizer)
      end.to raise_error(OctocatalogDiff::Errors::CatalogError)
      expect(logger_str.string).to match(/Failed build_catalog for foo-env/)
    end
  end

  describe '#add_parallel_result' do
    it 'should warn when catalog compilation is aborted' do
      options = { from_catalog: '-', to_catalog: '-', from_branch: 'foo', to_branch: 'bar' }
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      testobj = OctocatalogDiff::Util::Catalogs.new(options, logger)

      pcr = double('OctocatalogDiff::Util::Parallel::Result')
      allow(pcr).to receive(:status).and_return(nil)

      task = double('OctocatalogDiff::Util::Parallel::Task')
      allow(task).to receive(:args).and_return(branch: 'foo')
      key_task_tuple = [:from, task]

      result = { to: '!!!', from: 'blank' }
      testobj.send(:add_parallel_result, result, pcr, key_task_tuple)

      expect(logger_str.string).to match(/Catalog compile for foo was aborted due to another failure/)
      expect(result[:from]).to eq('blank')
    end

    context 'saving the catalog' do
      before(:each) { @tmpdir = Dir.mktmpdir }
      after(:each) { OctocatalogDiff::Spec.clean_up_tmpdir(@tmpdir) }

      it 'should save the catalog when requested' do
        filename = File.join(@tmpdir, 'catalog.json')
        options = {
          to_catalog: OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog.json'),
          from_catalog: OctocatalogDiff::Spec.fixture_path('catalogs/catalog-test-file.json'),
          from_save_catalog: filename
        }

        logger, logger_str = OctocatalogDiff::Spec.setup_logger
        testobj = OctocatalogDiff::Util::Catalogs.new(options, logger)
        result = testobj.send(:build_catalog_parallelizer)

        expect(logger_str.string).to match(Regexp.escape("Saved catalog to #{filename}"))
        expect(File.read(filename)).to eq(result[:from].catalog_json)
      end
    end

    it 'should format error and raise error when a catalog compile fails' do
      error_lines = [
        'Debug: You do not care about this',
        'Warning: This is some warning',
        'Error: Something went wrong at /foo/bar/environments/production/modules/something/manifests/init.pp:49'
      ]
      failed_catalog = OctocatalogDiff::Catalog.create(backend: :noop)
      allow(failed_catalog).to receive(:valid?).and_return(false)
      allow(failed_catalog).to receive(:compilation_dir).and_return('/foo/bar')
      allow(failed_catalog).to receive(:error_message).and_return(error_lines.join("\n"))

      pcr = double('OctocatalogDiff::Util::Parallel::Result')
      allow(pcr).to receive(:status).and_return(false)
      allow(pcr).to receive(:output).and_return(failed_catalog)

      task = double('OctocatalogDiff::Util::Parallel::Task')
      allow(task).to receive(:args).and_return(branch: 'foo')
      key_task_tuple = [:from, task]

      options = { from_catalog: '-', to_catalog: '-', from_branch: 'foo', to_branch: 'bar' }
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      testobj = OctocatalogDiff::Util::Catalogs.new(options, logger)

      result = { to: '!!!', from: 'blank' }
      lines = [
        'Debug: You do not care about this',
        'Warning: This is some warning',
        '\[Puppet Error\] Something went wrong at modules/something/manifests/init.pp:49'
      ]
      answer = Regexp.new(lines.join('(.|\n)*'))
      expect do
        testobj.send(:add_parallel_result, result, pcr, key_task_tuple)
      end.to raise_error(OctocatalogDiff::Errors::CatalogError, answer)

      expect(logger_str.string).to eq('')
    end
  end
end
