# frozen_string_literal: true

require_relative '../spec_helper'

require OctocatalogDiff::Spec.require_path('/catalog-util/bootstrap')

require 'fileutils'

describe OctocatalogDiff::CatalogUtil::Bootstrap do
  describe '#bootstrap_directory_parallelizer' do
    before(:each) do
      @dir = Dir.mktmpdir
    end

    after(:each) do
      OctocatalogDiff::Spec.clean_up_tmpdir(@dir)
    end

    it 'should raise error and log message if from branch is .' do
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      opts = {
        bootstrapped_from_dir: @dir,
        from_env: '.',
        basedir: '/'
      }
      expect do
        OctocatalogDiff::CatalogUtil::Bootstrap.bootstrap_directory_parallelizer(opts, logger)
      end.to raise_error(OctocatalogDiff::CatalogUtil::Bootstrap::BootstrapError, /Must specify a from-branch/)
      expect(logger_str.string).to match(/Must specify a from-branch/)
    end

    it 'should raise error and log message if to branch is .' do
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      opts = {
        bootstrapped_to_dir: @dir,
        to_env: '.',
        basedir: '/'
      }
      expect do
        OctocatalogDiff::CatalogUtil::Bootstrap.bootstrap_directory_parallelizer(opts, logger)
      end.to raise_error(OctocatalogDiff::CatalogUtil::Bootstrap::BootstrapError, /Must specify a to-branch/)
      expect(logger_str.string).to match(/Must specify a to-branch/)
    end

    it 'should raise an error and log message if no bootstrap directories are specified' do
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      opts = {}
      expect do
        OctocatalogDiff::CatalogUtil::Bootstrap.bootstrap_directory_parallelizer(opts, logger)
      end.to raise_error(OctocatalogDiff::CatalogUtil::Bootstrap::BootstrapError, /Specify one or more of/)
      expect(logger_str.string).to match(/Specify one or more of/)
    end

    context 'successful bootstraps' do
      before(:each) do
        @repo_dir = OctocatalogDiff::Spec.extract_fixture_repo('simple-repo')
        @dir = Dir.mktmpdir
        @dir2 = Dir.mktmpdir
      end

      after(:each) do
        OctocatalogDiff::Spec.clean_up_tmpdir(@repo_dir, @dir, @dir2)
      end

      it 'should complete one bootstrap in parallel' do
        logger, logger_str = OctocatalogDiff::Spec.setup_logger
        opts = {
          bootstrapped_to_dir: @dir,
          to_env: 'test-branch',
          basedir: File.join(@repo_dir, 'git-repo'),
          parallel: true
        }
        OctocatalogDiff::CatalogUtil::Bootstrap.bootstrap_directory_parallelizer(opts, logger)
        expect(logger_str.string).to match(/Begin 1 bootstrap\(s\)/)
        expect(logger_str.string).to match(/Success bootstrap_directory for to_dir/)
        expect(logger_str.string).to match(/Initialized parallel task result array: size=/)
        expect(File.file?(File.join(@dir, 'config', 'enc.sh'))).to eq(true)
      end

      it 'should complete one bootstrap in serial' do
        logger, logger_str = OctocatalogDiff::Spec.setup_logger
        opts = {
          bootstrapped_to_dir: @dir,
          to_env: 'test-branch',
          basedir: File.join(@repo_dir, 'git-repo'),
          parallel: false
        }
        OctocatalogDiff::CatalogUtil::Bootstrap.bootstrap_directory_parallelizer(opts, logger)
        expect(logger_str.string).to match(/Begin 1 bootstrap\(s\)/)
        expect(logger_str.string).to match(/Success bootstrap_directory for to_dir/)
        expect(logger_str.string).not_to match(/Initialized parallel task result array: size=/)
        expect(File.file?(File.join(@dir, 'config', 'enc.sh'))).to eq(true)
      end

      it 'should complete two bootstraps in parallel' do
        logger, logger_str = OctocatalogDiff::Spec.setup_logger
        opts = {
          bootstrapped_to_dir: @dir,
          bootstrapped_from_dir: @dir2,
          to_env: 'test-branch',
          from_env: 'master',
          basedir: File.join(@repo_dir, 'git-repo'),
          parallel: true
        }
        OctocatalogDiff::CatalogUtil::Bootstrap.bootstrap_directory_parallelizer(opts, logger)
        expect(logger_str.string).to match(/Begin 2 bootstrap\(s\)/)
        expect(logger_str.string).to match(/Success bootstrap_directory for to_dir/)
        expect(logger_str.string).to match(/Success bootstrap_directory for from_dir/)
        expect(logger_str.string).to match(/Initialized parallel task result array: size=/)
        expect(File.file?(File.join(@dir, 'config', 'enc.sh'))).to eq(true)
        expect(File.file?(File.join(@dir2, 'config', 'enc.sh'))).to eq(true)
      end

      it 'should complete two bootstraps in serial' do
        logger, logger_str = OctocatalogDiff::Spec.setup_logger
        opts = {
          bootstrapped_to_dir: @dir,
          bootstrapped_from_dir: @dir2,
          to_env: 'test-branch',
          from_env: 'master',
          basedir: File.join(@repo_dir, 'git-repo'),
          parallel: false
        }
        OctocatalogDiff::CatalogUtil::Bootstrap.bootstrap_directory_parallelizer(opts, logger)
        expect(logger_str.string).to match(/Begin 2 bootstrap\(s\)/)
        expect(logger_str.string).to match(/Success bootstrap_directory for to_dir/)
        expect(logger_str.string).to match(/Success bootstrap_directory for from_dir/)
        expect(logger_str.string).not_to match(/Initialized parallel task result array: size=/)
        expect(File.file?(File.join(@dir, 'config', 'enc.sh'))).to eq(true)
        expect(File.file?(File.join(@dir2, 'config', 'enc.sh'))).to eq(true)
      end

      it 'should run the bootstrap script' do
        logger, _logger_str = OctocatalogDiff::Spec.setup_logger
        opts = {
          bootstrapped_to_dir: @dir,
          bootstrapped_from_dir: @dir2,
          to_env: 'test-branch',
          from_env: 'master',
          basedir: File.join(@repo_dir, 'git-repo'),
          parallel: false,
          bootstrap_script: 'script/bootstrap.sh'
        }
        OctocatalogDiff::CatalogUtil::Bootstrap.bootstrap_directory_parallelizer(opts, logger)
        expect(File.file?(File.join(@dir, 'bootstrap_result.yaml'))).to eq(true)
        expect(File.file?(File.join(@dir2, 'bootstrap_result.yaml'))).to eq(true)
      end

      it 'should run a bootstrap script specified as an absolute path' do
        logger, _logger_str = OctocatalogDiff::Spec.setup_logger
        opts = {
          bootstrapped_to_dir: @dir,
          bootstrapped_from_dir: @dir2,
          to_env: 'test-branch',
          from_env: 'master',
          basedir: File.join(@repo_dir, 'git-repo'),
          parallel: false,
          bootstrap_script: File.join(@repo_dir, 'git-repo', 'script', 'bootstrap.sh')
        }
        OctocatalogDiff::CatalogUtil::Bootstrap.bootstrap_directory_parallelizer(opts, logger)
        expect(File.file?(File.join(@dir, 'bootstrap_result.yaml'))).to eq(true)
        expect(File.file?(File.join(@dir2, 'bootstrap_result.yaml'))).to eq(true)
      end
    end
  end
end
