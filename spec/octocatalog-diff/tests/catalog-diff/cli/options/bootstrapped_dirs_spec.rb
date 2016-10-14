require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_bootstrapped_dirs' do
    before(:all) do
      @tmpdir = Dir.mktmpdir
      Dir.mkdir(File.join(@tmpdir, 'existing-dir'), 0o755)
    end

    after(:all) do
      FileUtils.rm_rf(@tmpdir)
    end

    it 'should parse --bootstrapped-from-dir' do
      dir = File.join(@tmpdir, 'bootstrapped-from-dir')
      opts = ['--bootstrapped-from-dir', dir]
      result = run_optparse(opts)
      expect(Dir.exist?(dir)).to eq(true)
      expect(result[:bootstrapped_from_dir]).to eq(dir)
    end

    it 'should parse --bootstrapped-to-dir' do
      dir = File.join(@tmpdir, 'bootstrapped-to-dir')
      opts = ['--bootstrapped-to-dir', dir]
      result = run_optparse(opts)
      expect(Dir.exist?(dir)).to eq(true)
      expect(result[:bootstrapped_to_dir]).to eq(dir)
    end

    it 'should not fail if directory exists' do
      dir = File.join(@tmpdir, 'existing-dir')
      opts = ['--bootstrapped-to-dir', dir]
      expect(Dir.exist?(dir)).to eq(true)
      result = run_optparse(opts)
      expect(result[:bootstrapped_to_dir]).to eq(dir)
    end

    it 'should fail if directory cannot be created' do
      dir = File.join(@tmpdir, 'x', 'y')
      opts = ['--bootstrapped-to-dir', dir]
      expect do
        run_optparse(opts)
      end.to raise_error(Errno::ENOENT)
    end
  end
end
