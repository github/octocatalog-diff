require_relative 'spec_helper'

require OctocatalogDiff::Spec.require_path('/bootstrap')

describe OctocatalogDiff::Bootstrap do
  def b(options = {})
    OctocatalogDiff::Bootstrap.bootstrap(options)
  end

  describe '#bootstrap' do
    context 'options validation' do
      it 'should throw error if path is undefined' do
        expect { b(empty: true) }.to raise_error(ArgumentError, /\(:path\) undefined or wrong data type/)
      end

      it 'should throw error if path is the wrong data type' do
        expect { b(path: []) }.to raise_error(ArgumentError, /\(:path\) undefined or wrong data type/)
      end

      it 'should throw error if path is not a existing directory' do
        p = OctocatalogDiff::Spec.fixture_path('catalogs/asdlfkasfdlkja')
        expect { b(path: p) }.to raise_error(Errno::ENOENT)
      end

      it 'should throw error if path exists but is not a directory' do
        p = OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml')
        expect { b(path: p) }.to raise_error(Errno::ENOENT)
      end

      it 'should throw error if bootstrap script is the wrong data type' do
        p = OctocatalogDiff::Spec.fixture_path('repos')
        expect { b(path: p, bootstrap_script: []) }.to raise_error(ArgumentError, /\(:bootstrap_script\) undefined/)
      end

      it 'should throw error if bootstrap script is not an existing file' do
        p = OctocatalogDiff::Spec.fixture_path('repos')
        expect { b(path: p, bootstrap_script: 'aldsfk') }.to raise_error(Errno::ENOENT)
      end

      it 'should throw error if bootstrap script is not a file' do
        p = OctocatalogDiff::Spec.fixture_path('repos')
        expect { b(path: p, bootstrap_script: 'default') }.to raise_error(Errno::ENOENT)
      end
    end

    context 'with a dummy bootstrap script' do
      before(:each) do
        @d = OctocatalogDiff::Spec.shell_script_for_envvar_testing('bootstrap.sh')
        @env_save = {}
        %w(JACKPOT HOME PATH PWD).each { |x| @env_save[x] = ENV[x] }
      end

      after(:each) do
        OctocatalogDiff::Spec.clean_up_tmpdir(@d)
        %w(JACKPOT HOME PATH PWD).each { |x| ENV[x] = @env_save[x] }
      end

      it 'should execute bootstrap script with PWD set to path' do
        result = b(path: @d, bootstrap_script: 'script/bootstrap.sh', bootstrap_args: 'PWD')
        expect(result[:status_code]).to eq(32)
        expect(result[:output].strip).to eq(@d)
      end

      it 'should execute bootstrap script with HOME matching environment' do
        ENV['HOME'] = @d + '/adslfk'
        result = b(path: @d, bootstrap_script: 'script/bootstrap.sh', bootstrap_args: 'HOME')
        expect(result[:status_code]).to eq(32)
        expect(result[:output].strip).to eq(@d + '/adslfk')
      end

      it 'should execute bootstrap script with PATH matching environment' do
        ENV['PATH'] = @d + '/adslfk'
        result = b(path: @d, bootstrap_script: 'script/bootstrap.sh', bootstrap_args: 'PATH')
        expect(result[:status_code]).to eq(32)
        expect(result[:output].strip).to eq(@d + '/adslfk')
      end

      it 'should execute bootstrap script with BASEDIR matching argument' do
        opts = { path: @d, bootstrap_script: 'script/bootstrap.sh', basedir: 'chicken and fries' }
        result = b(opts.merge(bootstrap_args: 'BASEDIR'))
        expect(result[:status_code]).to eq(32)
        expect(result[:output].strip).to eq('chicken and fries')
      end

      it 'should not pass through an environment variable that is not explicitly passed through' do
        ENV['JACKPOT'] = 'If this makes it through something is broken'
        result = b(path: @d, bootstrap_script: 'script/bootstrap.sh', bootstrap_args: 'JACKPOT')
        expect(result[:status_code]).to eq(32)
        expect(result[:output].strip).to eq('')
      end
    end
  end
end
