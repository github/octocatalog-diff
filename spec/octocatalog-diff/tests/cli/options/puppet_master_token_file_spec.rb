# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  let(:fixture) { OctocatalogDiff::Spec.fixture_read('configs/puppet-master-token.txt').strip }

  context 'with a relative path' do
    describe '#opt_puppet_master_token_file' do
      let(:basedir) { OctocatalogDiff::Spec.fixture_path('configs') }

      it 'should handle --puppet-master-token-file with valid path' do
        result = run_optparse(['--basedir', basedir, '--puppet-master-token-file', 'puppet-master-token.txt'])
        expect(result[:to_puppet_master_token]).to eq(fixture)
        expect(result[:from_puppet_master_token]).to eq(fixture)
      end

      it 'should error if --puppet_master-token-file points to non-existing file' do
        expect do
          run_optparse(['--basedir', basedir, '--puppet-master-token-file', 'sdafjfkjlafjadsasf'])
        end.to raise_error(Errno::ENOENT)
      end

      it 'should error if --puppet-master-token-file is not passed an argument' do
        expect do
          run_optparse(['--basedir', basedir, '--puppet-master-token-file'])
        end.to raise_error(OptionParser::MissingArgument)
      end
    end
  end

  context 'with an absolute path' do
    describe '#opt_puppet_master_token_file' do
      it 'should handle --puppet-master-token-file with valid path' do
        result = run_optparse(
          [
            '--puppet-master-token-file',
            OctocatalogDiff::Spec.fixture_path('configs/puppet-master-token.txt')
          ]
        )
        expect(result[:to_puppet_master_token]).to eq(fixture)
        expect(result[:from_puppet_master_token]).to eq(fixture)
      end

      it 'should error if --puppet-master-token-file points to non-existing file' do
        expect do
          run_optparse(
            [
              '--puppet-master-token-file',
              OctocatalogDiff::Spec.fixture_path('configs/alsdkfalfdkjasdf')
            ]
          )
        end.to raise_error(Errno::ENOENT)
      end
    end
  end
end
