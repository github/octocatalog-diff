require_relative '../../spec_helper'
require OctocatalogDiff::Spec.require_path('/catalog-util/enc/script')

describe OctocatalogDiff::CatalogUtil::ENC::Script do
  describe '#new' do
    it 'should error if node is not specified' do
      opts = { enc: '/x', tempdir: '/y' }
      expect { OctocatalogDiff::CatalogUtil::ENC::Script.new(opts) }.to raise_error(ArgumentError, /requires :node/)
    end

    it 'should error if script is not specified' do
      opts = { node: 'foo', tempdir: '/y' }
      expect { OctocatalogDiff::CatalogUtil::ENC::Script.new(opts) }.to raise_error(ArgumentError, /requires :enc/)
    end

    it 'should not error even if tempdir is not specified' do
      opts = { node: 'foo', enc: '/x' }
      expect { OctocatalogDiff::CatalogUtil::ENC::Script.new(opts) }.not_to raise_error
    end
  end

  describe '#content' do
    it 'should return nil on an unexecuted object' do
      opts = { node: 'foo', enc: '/x' }
      testobj = OctocatalogDiff::CatalogUtil::ENC::Script.new(opts)
      expect(testobj.content).to eq(nil)
    end
  end

  describe '#error_message' do
    it 'should return expected message on an unexecuted object' do
      opts = { node: 'foo', enc: '/x' }
      testobj = OctocatalogDiff::CatalogUtil::ENC::Script.new(opts)
      expect(testobj.error_message).to eq('The execute method was never run')
    end
  end

  describe '#execute' do
    before(:each) { @tempdir = Dir.mktmpdir }

    after(:each) { OctocatalogDiff::Spec.clean_up_tmpdir(@tmpdir) }

    let(:fixture_path) { OctocatalogDiff::Spec.fixture_path('scripts/enc') }

    it 'should run cleanly with script that runs cleanly' do
      ENV['FOO'] = 'rspec-test'
      opts = { node: 'foo', tempdir: @tempdir, enc: File.join(fixture_path, 'succeeds-cleanly.sh') }
      testobj = OctocatalogDiff::CatalogUtil::ENC::Script.new(opts)
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      testobj.execute(logger)
      expect(logger_str.string).to match(%r{ENC::Script#execute for foo with .*/succeeds-cleanly.sh})
      expect(logger_str.string).not_to match(/Passing these extra environment variables/)
      expect(logger_str.string).to match(/ENC exited 0: \d\d+ bytes to STDOUT, 0 bytes to STDERR/)
      expect(logger_str.string).not_to match(/ENC STDERR:/)
      expect(testobj.content).to match(/This is to stdout/)
      expect(testobj.content).not_to match(/FOO is rspec-test/)
      expect(testobj.error_message).to eq(nil)
    end

    it 'should warn on STDERR from a script that outputs to STDERR' do
      opts = { node: 'foo', tempdir: @tempdir, enc: File.join(fixture_path, 'succeeds-stderr.sh') }
      testobj = OctocatalogDiff::CatalogUtil::ENC::Script.new(opts)
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      testobj.execute(logger)
      expect(logger_str.string).to match(%r{ENC::Script#execute for foo with .*/succeeds-stderr.sh})
      expect(logger_str.string).not_to match(/Passing these extra environment variables/)
      expect(logger_str.string).to match(/ENC exited 0: 18 bytes to STDOUT, 18 bytes to STDERR/)
      expect(logger_str.string).to match(/ENC STDERR: This is to stderr/)
      expect(testobj.content).to match(/This is to stdout/)
      expect(testobj.content).not_to match(/This is to stderr/)
      expect(testobj.error_message).to eq(nil)
    end

    it 'should pass environment variables' do
      ENV['FOO'] = 'rspec-test'
      opts = { node: 'foo', tempdir: @tempdir, enc: File.join(fixture_path, 'succeeds-cleanly.sh'), pass_env_vars: %w(FOO) }
      testobj = OctocatalogDiff::CatalogUtil::ENC::Script.new(opts)
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      testobj.execute(logger)
      expect(logger_str.string).to match(%r{ENC::Script#execute for foo with .*/succeeds-cleanly.sh})
      expect(logger_str.string).to match(/Passing these extra environment variables: \["FOO"\]/)
      expect(logger_str.string).to match(/ENC exited 0: \d\d+ bytes to STDOUT, 0 bytes to STDERR/)
      expect(logger_str.string).not_to match(/ENC STDERR:/)
      expect(testobj.content).to match(/This is to stdout/)
      expect(testobj.content).to match(/FOO is rspec-test/)
      expect(testobj.error_message).to eq(nil)
    end

    it 'should set and log error message upon failure - stderr only' do
      opts = { node: 'foo', tempdir: @tempdir, enc: File.join(fixture_path, 'fails-stderr-only.sh') }
      testobj = OctocatalogDiff::CatalogUtil::ENC::Script.new(opts)
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      testobj.execute(logger)
      expect(logger_str.string).to match(/ENC exited 1: 0 bytes to STDOUT, 18 bytes to STDERR/)
      expect(logger_str.string).to match(/Failed ENC printed this to STDERR: This is to stderr/)
      expect(logger_str.string).not_to match(/Failed ENC printed this to STDOUT:/)
      expect(testobj.content).to eq(nil)
      expect(testobj.error_message).to match(/ENC failed with status 1:  This is to stderr/)
    end

    it 'should set and log error message upon failure - stdout only' do
      opts = { node: 'foo', tempdir: @tempdir, enc: File.join(fixture_path, 'fails-stdout-only.sh') }
      testobj = OctocatalogDiff::CatalogUtil::ENC::Script.new(opts)
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      testobj.execute(logger)
      expect(logger_str.string).to match(/ENC exited 1: 18 bytes to STDOUT, 0 bytes to STDERR/)
      expect(logger_str.string).to match(/Failed ENC printed this to STDOUT: This is to stdout/)
      expect(logger_str.string).not_to match(/Failed ENC printed this to STDERR:/)
      expect(testobj.content).to eq(nil)
      expect(testobj.error_message).to match(/ENC failed with status 1: This is to stdout/)
    end

    it 'should set and log error message upon failure - stderr + stdout' do
      opts = { node: 'foo', tempdir: @tempdir, enc: File.join(fixture_path, 'fails-stdout-stderr.sh') }
      testobj = OctocatalogDiff::CatalogUtil::ENC::Script.new(opts)
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      testobj.execute(logger)
      expect(logger_str.string).to match(/ENC exited 1: 18 bytes to STDOUT, 18 bytes to STDERR/)
      expect(logger_str.string).to match(/Failed ENC printed this to STDERR: This is to stderr/)
      expect(logger_str.string).to match(/Failed ENC printed this to STDOUT: This is to stdout/)
      expect(testobj.content).to eq(nil)
      expect(testobj.error_message).to match(/ENC failed with status 1: This is to stdout\s+This is to stderr/)
    end
  end

  describe '#script_path' do
    it 'should return path that starts with /' do
      opts = { node: 'foo', enc: '/foo/bar.sh' }
      testobj = OctocatalogDiff::CatalogUtil::ENC::Script.new(opts)
      expect(testobj.script).to eq('/foo/bar.sh')
    end

    it 'should raise ArgumentError for relative path without tempdir' do
      opts = { node: 'foo', enc: 'foo/bar.sh' }
      expect { OctocatalogDiff::CatalogUtil::ENC::Script.new(opts) }.to raise_error(ArgumentError, /Script#new requires :tempdir/)
    end

    it 'should return relative path with existing environments/production' do
      opts = { node: 'foo', enc: 'environments/production/foo/bar.sh', tempdir: '/path/temp' }
      testobj = OctocatalogDiff::CatalogUtil::ENC::Script.new(opts)
      expect(testobj.script).to eq('/path/temp/environments/production/foo/bar.sh')
    end

    it 'should return relative path + environments/production' do
      opts = { node: 'foo', enc: 'foo/bar.sh', tempdir: '/path/temp' }
      testobj = OctocatalogDiff::CatalogUtil::ENC::Script.new(opts)
      expect(testobj.script).to eq('/path/temp/environments/production/foo/bar.sh')
    end
  end
end
