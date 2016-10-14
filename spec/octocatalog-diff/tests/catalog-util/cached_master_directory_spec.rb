require_relative '../spec_helper'
require OctocatalogDiff::Spec.require_path('/catalog-util/cached_master_directory')

require 'fileutils'
require 'json'
require 'open3'
require 'rugged'

describe OctocatalogDiff::CatalogUtil::CachedMasterDirectory do
  before(:all) do
    # Set up default options
    @default_options = {
      from_env: 'master',
      master_cache_branch: 'master', # It's usually master but our fixture doesn't have origin
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

    # If the fixture changes, this will have to be updated.
    @master_sha = '948b3874f5af7f91a5f370e306731fec048fa62e'
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

    it 'should have the expected SHA in the checked out repository' do
      pending 'repository checkout fixture missing' unless File.directory?(@default_options[:basedir])
      pending 'git and/or tar are required for most tests' unless @has_git
      out, error, exitcode = Open3.capture3(
        "git rev-parse #{@default_options[:master_cache_branch]}",
        chdir: @default_options[:basedir]
      )
      unless exitcode.exitstatus.zero?
        raise "Error: failed to git rev-parse #{@default_options[:master_cache_branch]}: #{error}"
      end
      test_master_sha = out.strip
      expect(test_master_sha).to eq(@master_sha)
    end

    it 'should have the expected SHA returned by rugged' do
      pending 'repository checkout fixture missing' unless File.directory?(@default_options[:basedir])
      repo = Rugged::Repository.new(@default_options[:basedir])
      test_rugged_sha = repo.branches['master'].target_id
      expect(test_rugged_sha).to eq(@master_sha)
    end
  end

  context 'test master directory' do
    describe '#run' do
      context 'error conditions' do
        before(:each) do
          @cachedir = Dir.mktmpdir
          @options = @default_options.merge(cached_master_dir: @cachedir)

          shafile = File.join(@cachedir, '.catalog-diff-master.sha')
          File.open(shafile, 'w') { |f| f.write @master_sha }
        end

        after(:each) do
          OctocatalogDiff::Spec.clean_up_tmpdir(@cachedir)
        end

        it 'should raise error if invalid cache dir is specified' do
          options = @options.merge(cached_master_dir: File.join(@cachedir, 'this', 'does', 'not', 'exist'))
          logger, _logger_string = OctocatalogDiff::Spec.setup_logger
          expect do
            OctocatalogDiff::CatalogUtil::CachedMasterDirectory.run(options, logger)
          end.to raise_error(Errno::ENOENT)
        end

        it 'should not bootstrap cache dir when SHA matches' do
          logger, logger_string = OctocatalogDiff::Spec.setup_logger
          OctocatalogDiff::CatalogUtil::CachedMasterDirectory.run(@options, logger)
          expect(Dir).not_to exist(File.join(@cachedir, 'script'))
          regex_to_match = Regexp.new("Cached master dir: bootstrapped=#{@master_sha}; current=#{@master_sha}")
          expect(logger_string.string).to match(regex_to_match)
        end

        it 'should raise error when cache is stale, so use can clean it out' do
          shafile = File.join(@cachedir, '.catalog-diff-master.sha')
          File.open(shafile, 'w') { |f| f.write('adkflsdkfjlkfjasfkjadsflk') }
          logger, logger_string = OctocatalogDiff::Spec.setup_logger
          expect do
            OctocatalogDiff::CatalogUtil::CachedMasterDirectory.run(@options, logger)
          end.to raise_error(Errno::EEXIST)
          regex_to_match = Regexp.new("Cached master dir: bootstrapped=adkflsdkfjlkfjasfkjadsflk; current=#{@master_sha}")
          expect(logger_string.string).to match(regex_to_match)
        end
      end

      context 'when a saved catalog is found' do
        before(:all) do
          @cachedir = Dir.mktmpdir
          @options = @default_options.merge(cached_master_dir: @cachedir)
          @saved_opts = @options.merge(node: 'foonode')
          @catalog_path = File.join(@cachedir, '.catalogs', 'foonode.json')
          Dir.mkdir File.join(@cachedir, '.catalogs')
          FileUtils.cp OctocatalogDiff::Spec.fixture_path('catalogs/catalog-1.json'), @catalog_path
          @logger, @logger_str = OctocatalogDiff::Spec.setup_logger
          OctocatalogDiff::CatalogUtil::CachedMasterDirectory.run(@saved_opts, @logger)
        end

        after(:all) do
          OctocatalogDiff::Spec.clean_up_tmpdir(@cachedir)
        end

        it 'should set options' do
          expect(@saved_opts[:from_catalog]).to eq(@catalog_path)
          expect(@saved_opts[:from_catalog_compilation_dir]).to eq(@cachedir)
        end

        it 'should log message' do
          expect(@logger_str.string).to match(/Setting --from-catalog=.*foonode\.json/)
        end
      end
    end

    describe '#cached_master_applicable_to_this_run?' do
      before(:each) do
        @cachedir = Dir.mktmpdir
        @options = @default_options.merge(cached_master_dir: @cachedir)

        shafile = File.join(@cachedir, '.catalog-diff-master.sha')
        File.open(shafile, 'w') { |f| f.write @master_sha }
      end

      after(:each) do
        OctocatalogDiff::Spec.clean_up_tmpdir(@cachedir)
      end

      it 'should return false when cached master directory is not specified' do
        options = {}
        result = OctocatalogDiff::CatalogUtil::CachedMasterDirectory.cached_master_applicable_to_this_run?(options)
        expect(result).to eq(false)
      end

      it 'should return false when cached master directory is nil' do
        options = @options.merge(cached_master_dir: nil)
        result = OctocatalogDiff::CatalogUtil::CachedMasterDirectory.cached_master_applicable_to_this_run?(options)
        expect(result).to eq(false)
      end

      it 'should return false when branches != master branch' do
        options = @options.merge(from_env: 'adsflksadf', to_env: 'ldkfjsadkjsfdf')
        result = OctocatalogDiff::CatalogUtil::CachedMasterDirectory.cached_master_applicable_to_this_run?(options)
        expect(result).to eq(false)
      end

      it 'should not hard-code origin/master' do
        options = @options.merge(from_env: 'origin/master', to_env: 'ldkfjsadkjsfdf')
        result = OctocatalogDiff::CatalogUtil::CachedMasterDirectory.cached_master_applicable_to_this_run?(options)
        expect(result).to eq(false)
      end

      it 'should return true when from branch is master' do
        options = @options.merge(from_env: 'master', to_env: 'ldkfjsadkjsfdf')
        result = OctocatalogDiff::CatalogUtil::CachedMasterDirectory.cached_master_applicable_to_this_run?(options)
        expect(result).to eq(true)
      end

      it 'should return true when to branch is master' do
        options = @options.merge(from_env: 'adsflksadf', to_env: 'master')
        result = OctocatalogDiff::CatalogUtil::CachedMasterDirectory.cached_master_applicable_to_this_run?(options)
        expect(result).to eq(true)
      end
    end

    describe '#git_repo_checkout_current?' do
      before(:each) do
        @cachedir = Dir.mktmpdir
        @options = @default_options.merge(cached_master_dir: @cachedir)

        shafile = File.join(@cachedir, '.catalog-diff-master.sha')
        File.open(shafile, 'w') { |f| f.write @master_sha }
      end

      after(:each) do
        OctocatalogDiff::Spec.clean_up_tmpdir(@cachedir)
      end

      it 'should return false if SHA file is missing' do
        shafile = File.join(@cachedir, '.catalog-diff-master.sha')
        FileUtils.rm_f shafile
        logger, logger_string = OctocatalogDiff::Spec.setup_logger
        result = OctocatalogDiff::CatalogUtil::CachedMasterDirectory.git_repo_checkout_current?(@options, logger)
        expect(result).to eq(false)
        expect(logger_string.string).to eq('')
      end

      it 'should return false if SHA file is different' do
        shafile = File.join(@cachedir, '.catalog-diff-master.sha')
        File.open(shafile, 'w') { |f| f.write('adkflsdkfjlkfjasfkjadsflk') }
        logger, logger_string = OctocatalogDiff::Spec.setup_logger
        result = OctocatalogDiff::CatalogUtil::CachedMasterDirectory.git_repo_checkout_current?(@options, logger)
        expect(result).to eq(false)
        regex_to_match = Regexp.new("DEBUG.*Cached master dir: bootstrapped=adkflsdkfjlkfjasfkjadsflk; current=#{@master_sha}\n")
        expect(logger_string.string).to match(regex_to_match)
      end

      it 'should retrieve SHA that matches `git rev-parse`' do
        logger, logger_string = OctocatalogDiff::Spec.setup_logger
        result = OctocatalogDiff::CatalogUtil::CachedMasterDirectory.git_repo_checkout_current?(@options, logger)
        expect(result).to eq(true), "SHA mismatch: expected #{@master_sha}"
        regex_to_match = Regexp.new("Cached master dir: bootstrapped=#{@master_sha}; current=#{@master_sha}")
        expect(logger_string.string).to match(regex_to_match)
      end
    end
  end

  describe '#git_repo_checkout_bootstrap' do
    context 'error conditions' do
      before(:each) do
        @cachedir = Dir.mktmpdir
        @options = @default_options.merge(cached_master_dir: @cachedir)

        shafile = File.join(@cachedir, '.catalog-diff-master.sha')
        File.open(shafile, 'w') { |f| f.write 'asdlfjkasdlfkj' }
      end

      after(:each) do
        OctocatalogDiff::Spec.clean_up_tmpdir(@cachedir)
      end

      it 'should raise error if :safe_to_delete_cached_master_dir is not set' do
        opts = @options.dup
        logger, logger_str = OctocatalogDiff::Spec.setup_logger
        expect do
          OctocatalogDiff::CatalogUtil::CachedMasterDirectory.git_repo_checkout_bootstrap(opts, logger)
        end.to raise_error(Errno::EEXIST, /needs to be deleted, so it can be re-created/)
        expect(logger_str.string).to eq('')
      end

      it 'should raise error if :safe_to_delete_cached_master_dir does not match' do
        opts = @options.merge(safe_to_delete_cached_master_dir: 'asdflaksdjfalskfj')
        logger, logger_str = OctocatalogDiff::Spec.setup_logger
        expect do
          OctocatalogDiff::CatalogUtil::CachedMasterDirectory.git_repo_checkout_bootstrap(opts, logger)
        end.to raise_error(Errno::EEXIST, /needs to be deleted, so it can be re-created/)
        expect(logger_str.string).to eq('')
      end
    end

    context 'when :safe_to_delete_cached_master_dir matches' do
      before(:all) do
        # Create cache dir
        @cachedir = Dir.mktmpdir

        # Change sha file to be something that does not match the git repo
        shafile = File.join(@cachedir, '.catalog-diff-master.sha')
        File.open(shafile, 'w') { |f| f.write 'asdlfjkasdlfkj' }

        # Put a dummy file in place in the old directory. The test can then see if the
        # directory with this file was removed and re-created, or if this file is still there
        # meaning that the directory was not removed and re-created.
        File.open(File.join(@cachedir, '.will-this-be-removed'), 'w') { |f| f.write('I hope so') }

        # Run the method under test so that results can be analyzed later
        opts = @default_options.merge(
          cached_master_dir: @cachedir,
          safe_to_delete_cached_master_dir: @cachedir,
          bootstrap_script: 'script/bootstrap.sh'
        )
        logger, @logger_str = OctocatalogDiff::Spec.setup_logger
        OctocatalogDiff::CatalogUtil::CachedMasterDirectory.git_repo_checkout_bootstrap(opts, logger)
      end

      after(:all) do
        OctocatalogDiff::Spec.clean_up_tmpdir(@cachedir)
      end

      it 'should remove the old cached master directory' do
        expect(File.file?(File.join(@cachedir, '.will-this-be-removed'))).to eq(false)
      end

      it 'should create the new cached directory' do
        expect(File.directory?(@cachedir)).to eq(true)
      end

      it 'should bootstrap the new cached master directory' do
        # This file is supposed to be created by script/bootstrap.sh
        expect(File.file?(File.join(@cachedir, 'bootstrap_result.yaml'))).to eq(true)
      end

      it 'should write the current sha to the cached master directory' do
        shafile = File.join(@cachedir, '.catalog-diff-master.sha')
        expect(File.read(shafile)).to eq('948b3874f5af7f91a5f370e306731fec048fa62e')
      end

      it 'should create a .catalogs directory' do
        expect(File.directory?(File.join(@cachedir, '.catalogs'))).to eq(true)
      end

      it 'should create the correct log messages' do
        str = @logger_str.string
        expect(str).to match(/Begin bootstrap cached master directory/)
        expect(str).to match(/Success bootstrap cached master directory/)
        expect(str).to match(/Cached master directory bootstrapped to 948b3874f5af7f91a5f370e306731fec048fa62e/)
        # There are more log messages too, but these are in other classes/methods
      end
    end
  end

  describe '#save_catalog_in_cache_dir' do
    def run(*args)
      OctocatalogDiff::CatalogUtil::CachedMasterDirectory.save_catalog_in_cache_dir(*args)
    end

    before(:all) do
      @catalog = OctocatalogDiff::Catalog.new(json: File.read(OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog.json')))
    end

    before(:each) do
      @dir = Dir.mktmpdir
      Dir.mkdir File.join(@dir, '.catalogs')
    end

    after(:each) do
      FileUtils.remove_entry_secure @dir if File.directory?(@dir)
    end

    it 'should return false with nil node' do
      result = run(nil, @dir, @catalog)
      expect(result).to eq(false)
    end

    it 'should return false with nil directory' do
      result = run('foo', nil, @catalog)
      expect(result).to eq(false)
    end

    it 'should return false with nil catalog' do
      result = run('foo', @dir, nil)
      expect(result).to eq(false)
    end

    it 'should return false with invalid catalog' do
      catalog = OctocatalogDiff::Catalog.new(json: 'this is not json')
      result = run('foo', @dir, catalog)
      expect(result).to eq(false)
    end

    it 'should return false if @dir/.catalogs does not exist' do
      Dir.rmdir File.join(@dir, '.catalogs')
      result = run('foo', @dir, @catalog)
      expect(result).to eq(false)
    end

    it 'should return false if @dir/.catalogs/<node>.json already exists' do
      File.open(File.join(@dir, '.catalogs', 'foo.json'), 'w') { |f| f.write 'Hi there' }
      result = run('foo', @dir, @catalog)
      expect(result).to eq(false)
    end

    it 'should return true and create the catalog' do
      result = run('foo', @dir, @catalog)
      file = File.join(@dir, '.catalogs', 'foo.json')
      expect(result).to eq(true)
      expect(File.file?(file)).to eq(true)
      expect(File.read(file)).to eq(@catalog.catalog_json)
    end
  end
end
