# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  describe '#opt_override_script_path' do
    context 'with relative path' do
      it 'should raise ArgumentError' do
        expect do
          run_optparse(['--override-script-path', '../foo/bar'])
        end.to raise_error(ArgumentError, 'Absolute path is required for --override-script-path')
      end
    end

    context 'with non-existing directory' do
      it 'should raise Errno::ENOENT' do
        expect(File).to receive(:'directory?').with('/foo/bar').and_return(false)
        expect do
          run_optparse(['--override-script-path', '/foo/bar'])
        end.to raise_error(Errno::ENOENT, /Invalid --override-script-path/)
      end
    end

    context 'with existing directory' do
      it 'should establish option' do
        expect(File).to receive(:'directory?').with('/foo/bar').and_return(true)
        result = run_optparse(['--override-script-path', '/foo/bar'])
        expect(result[:override_script_path]).to eq('/foo/bar')
      end
    end
  end
end
