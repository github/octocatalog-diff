require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_hiera_path' do
    it 'should set options[:hiera_path] when relative path is specified' do
      result = run_optparse(['--hiera-path', 'foo/bar/baz'])
      expect(result.fetch(:hiera_path, 'key-not-defined')).to eq('foo/bar/baz')
    end

    it 'should error if an absolute path is specified' do
      expect { run_optparse(['--hiera-path', '/foo/bar/baz']) }.to raise_error(ArgumentError, /must be a relative path/)
    end

    it 'should strip trailing slashes' do
      result = run_optparse(['--hiera-path', 'foo/bar/baz///'])
      expect(result.fetch(:hiera_path, 'key-not-defined')).to eq('foo/bar/baz')
    end

    it 'should error if empty' do
      expect { run_optparse(['--hiera-path', '']) }.to raise_error(ArgumentError, /must not be empty/)
    end

    it 'should error if --hiera-path and --hiera-path-strip are both specified' do
      expect do
        run_optparse(['--hiera-path', 'foo', '--hiera-path-strip', 'bar'])
      end.to raise_error(ArgumentError, /mutually exclusive/)
    end
  end
end
