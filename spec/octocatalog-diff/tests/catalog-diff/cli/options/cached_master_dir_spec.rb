require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_cached_master_dir' do
    before(:each) do
      @tmpdir = Dir.mktmpdir
    end

    after(:each) do
      FileUtils.rm_rf @tmpdir if Dir.exist?(@tmpdir)
    end

    it 'should create the directory if it does not exist' do
      path = File.join(@tmpdir, 'cached-master')
      _result = run_optparse(['--cached-master-dir', path])
      expect(Dir).to exist(path)
    end

    it 'should use an existing directory without throwing error' do
      path = File.join(@tmpdir, 'cached-master')
      Dir.mkdir path, 0o755
      _result = run_optparse(['--cached-master-dir', path])
      expect(Dir).to exist(path)
    end

    it 'should error if directory cannot be created due to missing levels' do
      path = File.join(@tmpdir, 'x', 'y', 'z', 'cached-master')
      expect { run_optparse(['--cached-master-dir', path]) }.to raise_error(Errno::ENOENT)
    end

    it 'should error if directory cannot be created due to something else existing there' do
      path = File.join(@tmpdir, 'cached-master')
      File.open(path, 'w') { |f| f.write 'Something is here' }
      expect { run_optparse(['--cached-master-dir', path]) }.to raise_error(Errno::EEXIST)
    end
  end
end
