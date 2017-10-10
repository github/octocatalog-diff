# frozen_string_literal: true

require_relative '../spec_helper'
require 'ostruct'
require OctocatalogDiff::Spec.require_path('/util/scriptrunner')

describe OctocatalogDiff::Util::ScriptRunner do
  describe '#initialize' do
    before(:each) do
      @logger, @logger_str = OctocatalogDiff::Spec.setup_logger
    end

    it 'should raise error when script cannot be found' do
      opts = {
        default_script: 'env/THIS-DOES-NOT-EXIST',
        working_dir: File.dirname(__FILE__),
        logger: @logger
      }
      expect { described_class.new(opts) }.to raise_error(Errno::ENOENT)
    end

    it 'should use override script when it is found' do
      opts = {
        default_script: 'asdflkjasf/scriptrunner_spec.rb',
        working_dir: File.join(File.dirname(__FILE__)),
        override_script_path: File.join(File.dirname(__FILE__)),
        logger: @logger
      }
      obj = described_class.new(opts)
      expect(obj.script_src).to eq(__FILE__)
      expect(@logger_str.string).to match(/Selecting.+scriptrunner_spec.rb from override script path/)
    end

    it 'should use default script when override is not found' do
      opts = {
        default_script: 'env/env.sh',
        working_dir: File.join(File.dirname(__FILE__)),
        override_script_path: File.join(File.dirname(__FILE__)),
        logger: @logger
      }
      obj = described_class.new(opts)
      answer = File.expand_path('../../../../scripts/env/env.sh', File.dirname(__FILE__))
      expect(obj.script_src).to eq(answer)
      expect(@logger_str.string).to match(/Did not find.+env.sh in override script path/)
    end

    it 'should use default script when override is not provided' do
      opts = {
        default_script: 'env/env.sh',
        working_dir: File.join(File.dirname(__FILE__)),
        logger: @logger
      }
      obj = described_class.new(opts)
      answer = File.expand_path('../../../../scripts/env/env.sh', File.dirname(__FILE__))
      expect(obj.script_src).to eq(answer)
      expect(@logger_str.string).to eq('')
    end
  end

  describe '#temp_script' do
    context 'when running under --parallel' do
      before(:each) do
        @base_tempdir = Dir.mktmpdir('ocd-tempdir')
      end

      after(:each) do
        OctocatalogDiff::Spec.clean_up_tmpdir(@base_tempdir)
      end

      it 'should create a temporary directory within the existing tempdir' do
        opts = {
          default_script: 'env/env.sh',
          existing_tempdir: @base_tempdir
        }
        subject = described_class.new(opts)
        script = subject.send(:temp_script, subject.script_src)

        regex = Regexp.new('\\A' + Regexp.escape(@base_tempdir) + '/ocd-scriptrunner[^/]+/env.sh\\z')
        expect(script).to match(regex)
      end
    end

    context 'when not running under --parallel' do
      it 'should create a new temporary directory and clean it up at_exit' do
        opts = {
          default_script: 'env/env.sh'
        }
        subject = described_class.new(opts)
        script = subject.send(:temp_script, subject.script_src)

        regex = Regexp.new('/ocd-scriptrunner[^/]+/env.sh\\z')
        expect(script).to match(regex)
      end
    end
  end

  describe '#run' do
    before(:each) do
      @logger, @logger_str = OctocatalogDiff::Spec.setup_logger
      @described_obj = described_class.new(
        default_script: 'env/env.sh',
        logger: @logger
      )
    end

    it 'should raise error when working directory cannot be found' do
      opts = {
        working_dir: File.join(File.dirname(__FILE__), 'THIS-DOES-NOT-EXIST')
      }
      expect { @described_obj.run(opts) }.to raise_error(Errno::ENOENT)
    end

    it 'should raise ScriptException when script fails' do
      stdout = 'Something was printed'
      stderr = "The command failed to run\nSomething must be busted\n"
      exitstatus = OpenStruct.new(exitstatus: 42)
      expect(Open3).to receive(:capture3).and_return([stdout, stderr, exitstatus])

      opts = {
        working_dir: File.dirname(__FILE__),
        argv: %w(foo bar)
      }

      expect { @described_obj.run(opts) }.to raise_error(OctocatalogDiff::Util::ScriptRunner::ScriptException)

      expect(@described_obj.stdout).to eq(stdout)
      expect(@described_obj.stderr).to eq(stderr)
      expect(@described_obj.exitcode).to eq(42)
    end

    context 'testing the environment' do
      before(:each) do
        ENV['THIS_SHOULD_NOT_BE_PASSED'] = 'foo'
      end

      after(:each) do
        ENV.delete('THIS_SHOULD_NOT_BE_PASSED')
      end

      it 'should set only the defined environment' do
        opts = {
          :working_dir  => File.dirname(__FILE__),
          :argv         => %w(foo bar),
          'HELLO_WORLD' => 'booyah'
        }
        result = @described_obj.run(opts)
        expect(result).to match(/HELLO_WORLD=booyah/)

        env_home = Regexp.escape(ENV['HOME'])
        expect(result).to match(/HOME=#{env_home}/)

        env_path = Regexp.escape(ENV['PATH'])
        expect(result).to match(/PATH=#{env_path}/)

        env_pwd = Regexp.escape(opts[:working_dir])
        expect(result).to match(/PWD=#{env_pwd}/)

        expect(result).not_to match(/THIS_SHOULD_NOT_BE_PASSED/)
      end
    end
  end
end
