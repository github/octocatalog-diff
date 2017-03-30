# frozen_string_literal: true

require_relative '../spec_helper'
require OctocatalogDiff::Spec.require_path('/util/scriptrunner')

describe OctocatalogDiff::Util::ScriptRunner do
  describe '#initialize' do
    before(:each) do
      @logger, @logger_str = OctocatalogDiff::Spec.setup_logger
    end

    it 'should raise error when script cannot be found' do
      opts = {
        default_script: 'git-extract/THIS-DOES-NOT-EXIST',
        working_dir: File.dirname(__FILE__),
        logger: @logger
      }
      expect { described_class.new(opts) }.to raise_error(Errno::ENOENT)
    end

    it 'should raise error when working directory cannot be found' do
      opts = {
        default_script: 'git-extract/git-extract.sh',
        working_dir: File.join(File.dirname(__FILE__), 'THIS-DOES-NOT-EXIST'),
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
      expect(obj.script).to eq(__FILE__)
      expect(@logger_str.string).to match(/Selecting.+scriptrunner_spec.rb from override script path/)
    end

    it 'should use default script when override is not found' do
      opts = {
        default_script: 'git-extract/git-extract.sh',
        working_dir: File.join(File.dirname(__FILE__)),
        override_script_path: File.join(File.dirname(__FILE__)),
        logger: @logger
      }
      obj = described_class.new(opts)
      answer = File.expand_path('../../../../scripts/git-extract/git-extract.sh', File.dirname(__FILE__))
      expect(obj.script).to eq(answer)
      expect(@logger_str.string).to match(/Did not find.+git-extract.sh in override script path/)
    end

    it 'should use default script when override is not provided' do
      opts = {
        default_script: 'git-extract/git-extract.sh',
        working_dir: File.join(File.dirname(__FILE__)),
        logger: @logger
      }
      obj = described_class.new(opts)
      answer = File.expand_path('../../../../scripts/git-extract/git-extract.sh', File.dirname(__FILE__))
      expect(obj.script).to eq(answer)
      expect(@logger_str.string).to eq('')
    end
  end
end
