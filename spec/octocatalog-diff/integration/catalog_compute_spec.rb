# frozen_string_literal: true

require_relative 'integration_helper'

require OctocatalogDiff::Spec.require_path('/cli/catalogs')
require OctocatalogDiff::Spec.require_path('/catalog')
require OctocatalogDiff::Spec.require_path('/facts')

describe 'computing catalog without hiera and with ENC' do
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

  context 'without hiera and with enc' do
    describe '#catalogs' do
      before(:all) do
        if @has_git && @has_tar && @has_bash
          options = @default_options.merge(enc: 'environments/production/config/enc.sh')
          logger, _logger_string = OctocatalogDiff::Spec.setup_logger
          testobj = OctocatalogDiff::Cli::Catalogs.new(options, logger)
          result = testobj.catalogs
          @to = result[:to]
          @from = result[:from]
        else
          @to = BadCatalog.new('Missing dependencies: git, tar, or bash')
          @from = BadCatalog.new('Missing dependencies: git, tar, or bash')
        end
      end

      it 'should create a valid from-catalog' do
        pending 'bash, git, and/or tar are required for most tests' unless @has_git && @has_tar && @has_bash
        expect(@from.valid?).to eq(true)
        expect(@from.resources).to be_a_kind_of(Array)
        expect(@from.resources.size).to eq(6)
      end

      it 'should create from-catalog file with content (not) derived from hiera' do
        pending @from.error_message unless @from.valid?

        resource = @from.resources.select { |x| x['type'] == 'File' && x['title'] == '/tmp/foo' }.first
        expect(resource).to be_a_kind_of(Hash), 'Catalog missing file { "/tmp/foo": ... }'
        expect(resource['file']).to be_a_kind_of(String)
        expect(resource['file']).to match(%r{/environments/production/modules/test/manifests/init.pp$})
        expect(resource['parameters']).to eq('content' => 'None Supplied')
      end

      it 'should create a valid to-catalog' do
        pending 'bash, git, and/or tar are required for most tests' unless @has_git && @has_tar && @has_bash
        expect(@to.valid?).to eq(true)
        expect(@to.resources).to be_a_kind_of(Array)
        expect(@to.resources.size).to eq(9)
      end

      it 'should create to-catalog file with content (not) derived from hiera' do
        pending @to.error_message unless @to.valid?

        resource = @to.resource(type: 'File', title: '/tmp/foo')
        expect(resource).to be_a_kind_of(Hash), 'Catalog missing file { "/tmp/foo": ... }'
        expect(resource['file']).to be_a_kind_of(String)
        expect(resource['file']).to match(%r{/environments/production/modules/test/manifests/init.pp$})
        answer_hash = { 'content' => 'None Supplied', 'group' => 'root', 'mode' => '0644', 'owner' => 'root' }
        expect(resource['parameters']).to eq(answer_hash)
      end

      it 'should create to-catalog file with content derived from enc' do
        pending @to.error_message unless @to.valid?

        resource = @to.resource(type: 'File', title: '/tmp/baz')
        expect(resource).to be_a_kind_of(Hash), 'Catalog missing file { "/tmp/baz": ... }'
        expect(resource['file']).to be_a_kind_of(String)
        expect(resource['file']).to match(%r{/environments/production/modules/test/manifests/xyz.pp$})
        expect(resource['parameters']).to eq('content' => 'test')
      end
    end
  end

  context 'without hiera and without enc' do
    describe '#catalogs' do
      before(:all) do
        if @has_git && @has_tar
          options = @default_options.dup
          logger, _logger_string = OctocatalogDiff::Spec.setup_logger
          testobj = OctocatalogDiff::Cli::Catalogs.new(options, logger)
          result = testobj.catalogs
          @to = result[:to]
          @from = result[:from]
        else
          @to = BadCatalog.new('Missing dependencies: git or tar')
          @from = BadCatalog.new('Missing dependencies: git or tar')
        end
      end

      it 'should create a valid from-catalog' do
        pending 'bash, git, and/or tar are required for most tests' unless @has_git && @has_tar
        expect(@from.valid?).to eq(true)
        expect(@from.resources).to be_a_kind_of(Array)
        expect(@from.resources.size).to eq(6)
      end

      it 'should create from-catalog file with content (not) derived from hiera' do
        pending @from.error_message unless @from.valid?

        resource = @from.resources.select { |x| x['type'] == 'File' && x['title'] == '/tmp/foo' }.first
        expect(resource).to be_a_kind_of(Hash), 'Catalog missing file { "/tmp/foo": ... }'
        expect(resource['file']).to be_a_kind_of(String)
        expect(resource['file']).to match(%r{/environments/production/modules/test/manifests/init.pp$})
        expect(resource['parameters']).to eq('content' => 'None Supplied')
      end

      it 'should create a valid to-catalog' do
        pending 'bash, git, and/or tar are required for most tests' unless @has_git && @has_tar
        expect(@to.valid?).to eq(true)
        expect(@to.resources).to be_a_kind_of(Array)
        expect(@to.resources.size).to eq(9)
      end

      it 'should create to-catalog file with content (not) derived from hiera' do
        pending @to.error_message unless @to.valid?

        resource = @to.resource(type: 'File', title: '/tmp/foo')
        expect(resource).to be_a_kind_of(Hash), 'Catalog missing file { "/tmp/foo": ... }'
        expect(resource['file']).to be_a_kind_of(String)
        expect(resource['file']).to match(%r{/environments/production/modules/test/manifests/init.pp$})
        answer_hash = { 'content' => 'None Supplied', 'group' => 'root', 'mode' => '0644', 'owner' => 'root' }
        expect(resource['parameters']).to eq(answer_hash)
      end

      it 'should create to-catalog file with content (not) derived from enc' do
        pending @to.error_message unless @to.valid?

        resource = @to.resource(type: 'File', title: '/tmp/baz')
        expect(resource).to be_a_kind_of(Hash), 'Catalog missing file { "/tmp/baz": ... }'
        expect(resource['file']).to be_a_kind_of(String)
        expect(resource['file']).to match(%r{/environments/production/modules/test/manifests/xyz.pp$})
        expect(resource['parameters']).to eq('content' => 'application is undef')
      end
    end
  end

  context 'with hiera config' do
    describe '#catalogs' do
      before(:all) do
        if @has_git && @has_tar
          options = @default_options.merge(hiera_config: 'environments/production/config/hiera.yaml',
                                           hiera_path_strip: '/var/lib/puppet')
          logger, _logger_string = OctocatalogDiff::Spec.setup_logger
          testobj = OctocatalogDiff::Cli::Catalogs.new(options, logger)
          result = testobj.catalogs
          @to = result[:to]
          @from = result[:from]
        else
          @to = BadCatalog.new('Missing dependencies: git or tar')
          @from = BadCatalog.new('Missing dependencies: git or tar')
        end
      end

      it 'should create a valid from-catalog' do
        pending 'bash, git, and/or tar are required for most tests' unless @has_git && @has_tar
        expect(@from.valid?).to eq(true)
        expect(@from.resources).to be_a_kind_of(Array)
        expect(@from.resources.size).to eq(6)
      end

      it 'should create from-catalog file with content derived from hiera' do
        pending @from.error_message unless @from.valid?

        resource = @from.resource(type: 'File', title: '/tmp/foo')
        expect(resource).to be_a_kind_of(Hash), 'Catalog missing file { "/tmp/foo": ... }'
        expect(resource['file']).to be_a_kind_of(String)
        expect(resource['file']).to match(%r{/environments/production/modules/test/manifests/init.pp$})
        expect(resource['parameters']).to eq('content' => 'Testy McTesterson')
      end

      it 'should create a valid to-catalog' do
        pending 'bash, git, and/or tar are required for most tests' unless @has_git && @has_tar
        expect(@to.valid?).to eq(true)
        expect(@to.resources).to be_a_kind_of(Array)
        expect(@to.resources.size).to eq(9)
      end

      it 'should create to-catalog file with content derived from hiera' do
        pending @to.error_message unless @to.valid?

        resource = @to.resource(type: 'File', title: '/tmp/foo')
        expect(resource).to be_a_kind_of(Hash), 'Catalog missing file { "/tmp/foo": ... }'
        expect(resource['file']).to be_a_kind_of(String)
        expect(resource['file']).to match(%r{/environments/production/modules/test/manifests/init.pp$})
        answer_hash = { 'content' => 'Testy McTesterson', 'group' => 'root', 'mode' => '0644', 'owner' => 'root' }
        expect(resource['parameters']).to eq(answer_hash) # content comes from hieradata/common.yaml
      end

      it 'should create to-catalog file with content (not) derived from enc' do
        pending @to.error_message unless @to.valid?

        resource = @to.resource(type: 'File', title: '/tmp/baz')
        expect(resource).to be_a_kind_of(Hash), 'Catalog missing file { "/tmp/baz": ... }'
        expect(resource['file']).to be_a_kind_of(String)
        expect(resource['file']).to match(%r{/environments/production/modules/test/manifests/xyz.pp$})
        expect(resource['parameters']).to eq('content' => 'application is undef')
      end

      it 'should populate the resources array' do
        resources = @to.resources.select { |x| x['type'] == 'File' && x['title'] == '/tmp/baz' }
        expect(resources.size).to eq(1)
        resource = resources.first
        expect(resource).to be_a_kind_of(Hash), 'Catalog missing file { "/tmp/baz": ... }'
        expect(resource['file']).to be_a_kind_of(String)
        expect(resource['file']).to match(%r{/environments/production/modules/test/manifests/xyz.pp$})
        expect(resource['parameters']).to eq('content' => 'application is undef')
      end
    end
  end

  context 'current working directory' do
    describe '#catalogs' do
      # This is a special case, where the "current working directory" is specified as the
      # source. This is used in local development and for a clean CI run. Bootstrapping is
      # avoided because the current directory is assumed to be bootstrapped already.
      before(:all) do
        if @has_git && @has_tar
          options = @default_options.merge(
            basedir: File.join(@git_checkout_dir, 'git-repo'),
            from_catalog: OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog.json'),
            hiera_config: 'environments/production/config/hiera.yaml',
            hiera_path_strip: '/var/lib/puppet',
            to_env: '.'
          )
          logger, _logger_string = OctocatalogDiff::Spec.setup_logger
          testobj = OctocatalogDiff::Cli::Catalogs.new(options, logger)
          result = testobj.catalogs
          @to = result[:to]
          @from = result[:from]
        else
          @to = BadCatalog.new('Missing dependencies: git or tar')
          @from = BadCatalog.new('Missing dependencies: git or tar')
        end
      end

      it 'should pass through the from-catalog' do
        pending 'bash, git, and/or tar are required for most tests' unless @has_git && @has_tar
        test_val = @from.catalog_json.gsub(/\s+/, '')
        answer_val = File.read(OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog.json')).gsub(/\s+/, '')
        expect(test_val).to eq(answer_val)
      end

      it 'should create a valid to-catalog' do
        pending 'bash, git, and/or tar are required for most tests' unless @has_git && @has_tar
        expect(@to.valid?).to eq(true)
        expect(@to.resources).to be_a_kind_of(Array)
        expect(@to.resources.size).to eq(6) # Note: The 'to' catalog in this case is the master branch
      end

      it 'should create to-catalog file with content derived from hiera' do
        pending @to.error_message unless @to.valid?

        resource = @to.resource(type: 'File', title: '/tmp/foo')
        expect(resource).to be_a_kind_of(Hash), 'Catalog missing file { "/tmp/foo": ... }'
        expect(resource['file']).to be_a_kind_of(String)
        expect(resource['file']).to match(%r{/environments/production/modules/test/manifests/init.pp$})
        expect(resource['parameters']).to eq('content' => 'Testy McTesterson')
      end

      it 'should not pollute the working directory with temporary configuration files' do
        # Pointless to test this (and could get false results) if the catalog compilation didn't work
        # in the target directory at all. There is already a test that the to-catalog is valid above,
        # so this one will be marked pending in that case.
        pending 'Catalog compilation in the tested directory did not succeed' unless @to.valid?
        expect(@to.valid?).to eq(true)

        files = %w(hiera.yaml puppetdb.conf routes.yaml)
        files.each do |file|
          path = File.join(@git_checkout_dir, 'git-repo', file)
          expect(File.file?(path)).to eq(false)
        end
      end
    end
  end
end
