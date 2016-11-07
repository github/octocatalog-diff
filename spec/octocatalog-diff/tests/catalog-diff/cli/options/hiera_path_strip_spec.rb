require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_hiera_path_strip' do
    it 'should set options[:hiera_path_strip] when path is specified' do
      result = run_optparse(['--hiera-path-strip', '/var/tmp/foo/bar/baz'])
      expect(result.fetch(:hiera_path_strip, 'key-not-defined')).to eq('/var/tmp/foo/bar/baz')
    end

    it 'should allow empty' do
      result = run_optparse(['--hiera-path-strip', ''])
      expect(result.fetch(:hiera_path_strip, 'key-not-defined')).to eq('')
    end

    it 'should error if --hiera-path and --hiera-path-strip are both specified' do
      expect do
        run_optparse(['--hiera-path-strip', 'foo', '--hiera-path', 'bar'])
      end.to raise_error(ArgumentError, /mutually exclusive/)
    end

    it 'should recognize --no-hiera-path-strip option' do
      result = run_optparse(['--no-hiera-path-strip'])
      expect(result.fetch(:hiera_path_strip, 'key-not-defined')).to eq(:none)
    end

    it 'should error if --hiera-path-strip and --no-hiera-path-strip are used together (1)' do
      expect do
        run_optparse(['--hiera-path-strip', 'foo/bar/baz', '--no-hiera-path-strip'])
      end.to raise_error(ArgumentError, /mutually exclusive/)
    end

    it 'should error if --hiera-path-strip and --no-hiera-path-strip are used together (2)' do
      expect do
        run_optparse(['--no-hiera-path-strip', '--hiera-path-strip', 'foo/bar/baz'])
      end.to raise_error(ArgumentError, /mutually exclusive/)
    end
  end
end
