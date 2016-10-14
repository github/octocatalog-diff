require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_hiera_path_strip' do
    it 'should set options[:hiera_path_strip] when path is specified' do
      result = run_optparse(['--hiera-path-strip', '/var/tmp/foo/bar/baz'])
      expect(result.fetch(:hiera_path_strip, 'key-not-defined')).to eq('/var/tmp/foo/bar/baz')
    end
  end
end
