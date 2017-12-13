# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  context 'with a relative path' do
    describe '#opt_puppetdb_token_file' do
      let(:basedir) { OctocatalogDiff::Spec.fixture_path('configs') }

      it 'should handle --puppetdb-token-file with valid path' do
        result = run_optparse(['--basedir', basedir, '--puppetdb-token-file', 'puppetdb-token.txt'])
        expect(result[:puppetdb_token]).to eq(OctocatalogDiff::Spec.fixture_read('configs/puppetdb-token.txt'))
      end

      it 'should error if --puppetdb-token-file points to non-existing file' do
        expect do
          run_optparse(['--basedir', basedir, '--puppetdb-token-file', 'sdafjfkjlafjadsasf'])
        end.to raise_error(Errno::ENOENT)
      end

      it 'should error if --puppetdb-token-file is not passed an argument' do
        expect { run_optparse(['--basedir', basedir, '--puppetdb-token-file']) }.to raise_error(OptionParser::MissingArgument)
      end
    end
  end

  context 'with an absolute path' do
    describe '#opt_puppetdb_token_file' do
      it 'should handle --puppetdb-token-file with valid path' do
        result = run_optparse(['--puppetdb-token-file', OctocatalogDiff::Spec.fixture_path('configs/puppetdb-token.txt')])
        expect(result[:puppetdb_token]).to eq(OctocatalogDiff::Spec.fixture_read('configs/puppetdb-token.txt'))
      end

      it 'should error if --puppetdb-token-file points to non-existing file' do
        expect do
          run_optparse(['--puppetdb-token-file', OctocatalogDiff::Spec.fixture_path('configs/alsdkfalfdkjasdf')])
        end.to raise_error(Errno::ENOENT)
      end
    end
  end
end
