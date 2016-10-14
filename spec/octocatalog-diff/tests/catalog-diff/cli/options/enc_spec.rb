require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  context 'with a relative path' do
    describe '#opt_enc' do
      let(:basedir) { OctocatalogDiff::Spec.fixture_path('configs') }
      let(:enc) { 'trivial-enc.sh' }

      it 'should handle --enc with valid path' do
        result = run_optparse(['--basedir', basedir, '--enc', enc])
        expect(result[:enc]).to eq(OctocatalogDiff::Spec.fixture_path('configs/trivial-enc.sh'))
      end

      it 'should error if --enc points to non-existing file' do
        expect do
          run_optparse(['--basedir', basedir, '--enc', 'sdafjfkjlafjadsasf'])
        end.to raise_error(Errno::ENOENT)
      end

      it 'should error if --enc is not passed an argument' do
        expect { run_optparse(['--basedir', basedir, '--enc']) }.to raise_error(OptionParser::MissingArgument)
      end

      it 'should handle --no-enc to disable ENC' do
        result = run_optparse(['--basedir', basedir, '--no-enc'])
        expect(result[:no_enc]).to eq(true)
      end

      it 'should disable ENC with --no-enc and --enc both provided' do
        result = run_optparse(['--basedir', basedir, '--no-enc', '--enc', enc])
        expect(result[:enc]).to be(nil)
      end

      it 'should disable ENC with --enc and --no-enc both provided' do
        result = run_optparse(['--basedir', basedir, '--enc', enc, '--no-enc'])
        expect(result[:enc]).to be(nil)
      end
    end
  end

  context 'with an absolute path' do
    describe '#opt_enc' do
      it 'should handle --enc with valid path' do
        result = run_optparse(['--enc', OctocatalogDiff::Spec.fixture_path('configs/trivial-enc.sh')])
        expect(result[:enc]).to eq(OctocatalogDiff::Spec.fixture_path('configs/trivial-enc.sh'))
      end

      it 'should error if --enc points to non-existing file' do
        expect do
          run_optparse(['--enc', OctocatalogDiff::Spec.fixture_path('configs/alsdkfalfdkjasdf')])
        end.to raise_error(Errno::ENOENT)
      end
    end
  end

  context 'with to/from enc' do
    describe '#opt_enc' do
      it 'should handle --to-enc with valid path' do
        result = run_optparse(['--to-enc', OctocatalogDiff::Spec.fixture_path('configs/trivial-enc.sh')])
        expect(result[:to_enc]).to eq(OctocatalogDiff::Spec.fixture_path('configs/trivial-enc.sh'))
      end
    end

    describe '#opt_enc' do
      it 'should handle --from-enc with valid path' do
        result = run_optparse(['--from-enc', OctocatalogDiff::Spec.fixture_path('configs/trivial-enc.sh')])
        expect(result[:from_enc]).to eq(OctocatalogDiff::Spec.fixture_path('configs/trivial-enc.sh'))
      end
    end
  end
end
