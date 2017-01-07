# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::Cli::Options do
  context 'with a relative path' do
    describe '#opt_pe_enc_token_file' do
      let(:basedir) { OctocatalogDiff::Spec.fixture_path('configs') }

      it 'should handle --pe-enc-token-file with valid path' do
        result = run_optparse(['--basedir', basedir, '--pe-enc-token-file', 'pe-enc-token.txt'])
        expect(result[:pe_enc_token]).to eq(OctocatalogDiff::Spec.fixture_read('configs/pe-enc-token.txt'))
      end

      it 'should error if --pe-enc-token-file points to non-existing file' do
        expect do
          run_optparse(['--basedir', basedir, '--pe-enc-token-file', 'sdafjfkjlafjadsasf'])
        end.to raise_error(Errno::ENOENT)
      end

      it 'should error if --pe-enc-token-file is not passed an argument' do
        expect { run_optparse(['--basedir', basedir, '--pe-enc-token-file']) }.to raise_error(OptionParser::MissingArgument)
      end
    end
  end

  context 'with an absolute path' do
    describe '#opt_pe_enc_token_file' do
      it 'should handle --pe-enc-token-file with valid path' do
        result = run_optparse(['--pe-enc-token-file', OctocatalogDiff::Spec.fixture_path('configs/pe-enc-token.txt')])
        expect(result[:pe_enc_token]).to eq(OctocatalogDiff::Spec.fixture_read('configs/pe-enc-token.txt'))
      end

      it 'should error if --pe-enc-token-file points to non-existing file' do
        expect do
          run_optparse(['--pe-enc-token-file', OctocatalogDiff::Spec.fixture_path('configs/alsdkfalfdkjasdf')])
        end.to raise_error(Errno::ENOENT)
      end
    end
  end
end
