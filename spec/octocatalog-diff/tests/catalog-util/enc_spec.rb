# frozen_string_literal: true

require_relative '../spec_helper'
require OctocatalogDiff::Spec.require_path('/api/v1')
require OctocatalogDiff::Spec.require_path('/catalog-util/enc')

describe OctocatalogDiff::CatalogUtil::ENC do
  describe '#backend' do
    it 'should acknowledge a hard-coded :noop backend' do
      opts = { backend: :noop }
      testobj = OctocatalogDiff::CatalogUtil::ENC.new(opts)
      expect(testobj.builder).to eq('OctocatalogDiff::CatalogUtil::ENC::Noop')
    end

    it 'should acknowledge a hard-coded :script backend' do
      opts = { backend: :script, node: 'foo', enc: '/x' }
      testobj = OctocatalogDiff::CatalogUtil::ENC.new(opts)
      expect(testobj.builder).to eq('OctocatalogDiff::CatalogUtil::ENC::Script')
    end

    it 'should raise error for unrecognized, specified backend' do
      opts = { backend: :chicken }
      expect { OctocatalogDiff::CatalogUtil::ENC.new(opts) }.to raise_error(ArgumentError, /Unknown backend :chicken/)
    end

    it 'should choose script backend when :script is provided' do
      opts = { enc: '/x', node: 'foo' }
      testobj = OctocatalogDiff::CatalogUtil::ENC.new(opts)
      expect(testobj.builder).to eq('OctocatalogDiff::CatalogUtil::ENC::Script')
    end

    it 'should raise error for unrecognized, undetermined backend' do
      opts = {}
      expect { OctocatalogDiff::CatalogUtil::ENC.new(opts) }.to raise_error(ArgumentError, /Unable to determine ENC backend/)
    end
  end

  context 'with a mocked backend' do
    context 'after success' do
      before(:each) do
        backend = double('OctocatalogDiff::CatalogUtil::ENC::FakeBackend')
        allow(backend).to receive(:content).and_return('Hello Content')
        allow(backend).to receive(:error_message).and_return(nil)
        allow(OctocatalogDiff::CatalogUtil::ENC::Noop).to receive(:new).and_return(backend)
      end

      describe '#content' do
        it 'should return expected value' do
          opts = { backend: :noop }
          testobj = OctocatalogDiff::CatalogUtil::ENC.new(opts)
          expect(testobj.content).to eq('Hello Content')
        end
      end

      describe '#error_message' do
        it 'should return nil' do
          opts = { backend: :noop }
          testobj = OctocatalogDiff::CatalogUtil::ENC.new(opts)
          expect(testobj.error_message).to eq(nil)
        end
      end
    end

    context 'after failure' do
      before(:each) do
        backend = double('OctocatalogDiff::CatalogUtil::ENC::FakeBackend')
        allow(backend).to receive(:content).and_return(nil)
        allow(backend).to receive(:error_message).and_return('It broke')
        allow(OctocatalogDiff::CatalogUtil::ENC::Noop).to receive(:new).and_return(backend)
      end

      describe '#content' do
        it 'should return nil' do
          opts = { backend: :noop }
          testobj = OctocatalogDiff::CatalogUtil::ENC.new(opts)
          expect(testobj.content).to eq(nil)
        end
      end

      describe '#error_message' do
        it 'should return expected value' do
          opts = { backend: :noop }
          testobj = OctocatalogDiff::CatalogUtil::ENC.new(opts)
          expect(testobj.error_message).to eq('It broke')
        end
      end
    end

    context 'executing' do
      before(:each) do
        @logger, @logger_str = OctocatalogDiff::Spec.setup_logger
        backend = double('OctocatalogDiff::CatalogUtil::ENC::FakeBackend')
        allow(backend).to receive(:execute) { |logger| logger.debug 'Hello there' }
        allow(OctocatalogDiff::CatalogUtil::ENC::Noop).to receive(:new).and_return(backend)
      end

      describe '#execute' do
        it 'should use the logger object directly supplied' do
          opts = { backend: :noop }
          testobj = OctocatalogDiff::CatalogUtil::ENC.new(opts)
          testobj.send(:execute, @logger)
          expect(@logger_str.string).to match(/Hello there/)
        end

        it 'should use the logger object supplied in options' do
          opts = { backend: :noop, logger: @logger }
          testobj = OctocatalogDiff::CatalogUtil::ENC.new(opts)
          testobj.send(:execute)
          expect(@logger_str.string).to match(/Hello there/)
        end

        it 'should not fail if no logger object is supplied' do
          opts = { backend: :noop }
          testobj = OctocatalogDiff::CatalogUtil::ENC.new(opts)
          expect { testobj.send(:execute) }.not_to raise_error
        end

        it 'should only run once' do
          opts = { backend: :noop, logger: @logger }
          testobj = OctocatalogDiff::CatalogUtil::ENC.new(opts)
          testobj.send(:execute)
          testobj.send(:execute)
          lines = @logger_str.string.strip.split(/\n/)
          expect(@logger_str.string).to match(/Hello there/)
          expect(lines.size).to eq(1)
        end
      end
    end
  end

  describe '#override_enc_parameters' do
    before(:each) do
      @logger, @logger_str = OctocatalogDiff::Spec.setup_logger
    end

    it 'should make no changes if no overrides are specified' do
      subject = described_class.allocate
      subject.instance_variable_set('@options', {})
      subject.instance_variable_set('@content', "--- {}\n")
      subject.send(:override_enc_parameters, @logger)
      expect(subject.instance_variable_get('@content')).to eq("--- {}\n")
      expect(@logger_str.string).to eq('')
    end

    it 'should update @content based on override' do
      options = {
        enc_override: [OctocatalogDiff::API::V1::Override.create_from_input('foo=(string)bar')]
      }
      subject = described_class.allocate
      subject.instance_variable_set('@options', options)
      subject.instance_variable_set('@content', "--- {}\n")
      subject.send(:override_enc_parameters, @logger)
      expect(subject.instance_variable_get('@content')).to eq("---\nfoo: bar\n")
      logs = @logger_str.string.split(/\n/).compact.map { |x| OctocatalogDiff::Spec.strip_log_message(x) }
      expect(logs).to include('DEBUG - ENC override: foo = "bar"')
    end
  end

  describe '#merge_enc_param' do
    before(:each) do
      @logger, @logger_str = OctocatalogDiff::Spec.setup_logger
      @subject = described_class.allocate
    end

    it 'should replace a parameter at the top level' do
      struct = {
        'parameters' => {
          'foo' => 'bar',
          'baz' => 'fuzz'
        }
      }
      @subject.send(:merge_enc_param, struct, 'parameters', 'baz4')
      expect(struct['parameters']).to eq('baz4')
    end

    it 'should add a parameter at the top level' do
      struct = {
        'parameters' => {
          'foo' => 'bar',
          'baz' => 'fuzz'
        }
      }
      @subject.send(:merge_enc_param, struct, 'stuffs', 'baz4')
      expect(struct['stuffs']).to eq('baz4')
    end

    it 'should add a multi-depth parameter at the top level' do
      struct = {
        'parameters' => {
          'foo' => 'bar',
          'baz' => 'fuzz'
        }
      }
      @subject.send(:merge_enc_param, struct, 'stuffs::morestuffs', 'baz4')
      expect(struct['stuffs']['morestuffs']).to eq('baz4')
    end

    it 'should remove a parameter at the top level' do
      struct = {
        'parameters' => {
          'foo' => 'bar',
          'baz' => 'fuzz'
        }
      }
      @subject.send(:merge_enc_param, struct, 'parameters', nil)
      expect(struct).to eq({})
    end

    it 'should error if breaking the structure' do
      struct = {
        'parameters' => {
          'foo' => 'bar',
          'baz' => 'fuzz'
        }
      }
      expect do
        @subject.send(:merge_enc_param, struct, 'parameters::foo::baz3', 'baz4')
      end.to raise_error(ArgumentError, /Attempt to override String with hash for foo::baz3/)
    end

    it 'should overwrite a key nested in a hash with same datatype' do
      struct = {
        'parameters' => {
          'foo' => 'bar',
          'baz' => 'fuzz'
        }
      }
      @subject.send(:merge_enc_param, struct, 'parameters::foo', 'baz4')
      expect(struct['parameters']['foo']).to eq('baz4')
    end

    it 'should overwrite a key nested in a hash with different datatype' do
      struct = {
        'parameters' => {
          'foo' => 'bar',
          'baz' => 'fuzz'
        }
      }
      @subject.send(:merge_enc_param, struct, 'parameters::foo', %w(kittens puppies))
      expect(struct['parameters']['foo']).to eq(%w(kittens puppies))
    end

    it 'should delete a key nested in a hash' do
      struct = {
        'parameters' => {
          'foo' => 'bar',
          'baz' => 'fuzz'
        }
      }
      @subject.send(:merge_enc_param, struct, 'parameters::foo', nil)
      expect(struct['parameters'].key?('foo')).to eq(false)
    end

    it 'should overwrite a key nested deeply in a hash with same datatype' do
      struct = {
        'parameters' => {
          'foo' => { 'bar' => { 'baz' => 'chicken' } },
          'baz' => 'fuzz'
        }
      }
      @subject.send(:merge_enc_param, struct, 'parameters::foo::bar::baz', 'turkey')
      expect(struct['parameters']['foo']['bar']['baz']).to eq('turkey')
    end
  end
end
