# frozen_string_literal: true

require_relative '../../spec_helper'

require OctocatalogDiff::Spec.require_path('/api/v1/config')

describe OctocatalogDiff::API::V1::Config do
  before(:each) do
    @logger, @logger_str = OctocatalogDiff::Spec.setup_logger
  end

  after(:each) do
    begin
      OctocatalogDiff.send(:remove_const, :Config)
    rescue NameError # rubocop:disable Lint/HandleExceptions
      # Don't care if it's not defined already
    end
  end

  describe '#config' do
    let(:filename) { '/fizz/buzz.rb' }

    context 'with missing configuration file' do
      let(:pattern) { Regexp.new("Unable to find configuration file in #{filename}") }

      context 'in test mode' do
        it 'should raise ConfigurationFileNotFoundError' do
          expect(File).to receive(:'file?').with(filename).and_return(false)
          expect do
            described_class.config(logger: @logger, filename: filename, test: true)
          end.to raise_error(OctocatalogDiff::API::V1::Config::ConfigurationFileNotFoundError, pattern)
        end
      end

      context 'in normal mode' do
        it 'should return {}' do
          expect(File).to receive(:'file?').with(filename).and_return(false)
          result = described_class.config(logger: @logger, filename: filename)
          expect(result).to eq({})
          expect(@logger_str.string).to match(pattern)
        end
      end
    end

    context 'with found configuration file' do
      let(:pattern) { Regexp.new('Loaded 1 settings from /fizz/buzz.rb') }
      let(:debug_pattern) { Regexp.new(':foo => \(String\) "bar"') }

      context 'in test mode' do
        it 'should print settings to log and return settings' do
          expect(File).to receive(:'file?').with(filename).and_return(true)
          expect(described_class).to receive(:load_config_file).and_return(foo: 'bar')
          result = described_class.config(logger: @logger, filename: filename, test: true)
          expect(result).to eq(foo: 'bar')
          expect(@logger_str.string).to match(pattern)
          expect(@logger_str.string).to match(debug_pattern)
        end
      end

      context 'in normal mode' do
        it 'should return settings' do
          expect(File).to receive(:'file?').with(filename).and_return(true)
          expect(described_class).to receive(:load_config_file).and_return(foo: 'bar')
          result = described_class.config(logger: @logger, filename: filename)
          expect(result).to eq(foo: 'bar')
          expect(@logger_str.string).to match(pattern)
          expect(@logger_str.string).not_to match(debug_pattern)
        end
      end
    end
  end

  describe '#debug_config_file' do
    it 'should raise error if non-hash is passed in' do
      expect do
        described_class.debug_config_file(nil, @logger)
      end.to raise_error(ArgumentError, /Settings must be hash not NilClass/)
    end

    it 'should log keys and values in the hash' do
      described_class.debug_config_file({ foo: 'bar', baz: ['buzz'] }, @logger)
      expect(@logger_str.string).to match(/:foo => \(String\) "bar"/)
      expect(@logger_str.string).to match(/:baz => \(Array\) \["buzz"\]/)
    end
  end

  describe '#load_config_file' do
    context 'with a non-existent file' do
      let(:filename) { OctocatalogDiff::Spec.fixture_path('this-does-not-exist.rb') }

      it 'should raise Errno::ENOENT' do
        expect do
          described_class.load_config_file(filename, @logger)
        end.to raise_error(Errno::ENOENT, /File.+doesn't exist/)
      end

      it 'should log fatal message' do
        exception = nil
        begin
          described_class.load_config_file(filename, @logger)
        rescue Errno::ENOENT => exc
          exception = exc
        end
        expect(exception.message).to match(/this-does-not-exist.rb doesn't exist/)
        expect(@logger_str.string).to match(/FATAL .+ Errno::ENOENT error with .+this-does-not-exist.rb/)
      end
    end

    context 'with an invalid file' do
      let(:filename) { OctocatalogDiff::Spec.fixture_path('cli-configs/not-ruby.rb') }

      it 'should raise SyntaxError' do
        expect do
          described_class.load_config_file(filename, @logger)
        end.to raise_error(SyntaxError)
      end

      it 'should log fatal message' do
        exception = nil
        begin
          described_class.load_config_file(filename, @logger)
        rescue SyntaxError => exc
          exception = exc
        end
        expect(exception).to be_a_kind_of(SyntaxError)
        expect(exception.message).to match(/unexpected tIDENTIFIER/)
        expect(@logger_str.string).to match(/DEBUG -- : Loading octocatalog-diff configuration from/)
        expect(@logger_str.string).to match(/FATAL .+ SyntaxError error with .+not-ruby.rb/)
      end
    end

    context 'with a file that throws an exception' do
      let(:filename) { OctocatalogDiff::Spec.fixture_path('cli-configs/invalid.rb') }

      it 'should raise RuntimeError' do
        expect do
          described_class.load_config_file(filename, @logger)
        end.to raise_error(RuntimeError, /Fizz Buzz/)
      end

      it 'should log fatal message' do
        exception = nil
        begin
          described_class.load_config_file(filename, @logger)
        rescue RuntimeError => exc
          exception = exc
        end
        expect(exception).to be_a_kind_of(RuntimeError)
        expect(exception.message).to eq('Fizz Buzz')
        expect(@logger_str.string).to match(/DEBUG -- : Loading octocatalog-diff configuration from/)
        expect(@logger_str.string).to match(/FATAL .+ RuntimeError error with .+invalid.rb/)
      end
    end

    context 'with a file that does not define a .config method' do
      let(:filename) { OctocatalogDiff::Spec.fixture_path('cli-configs/not-proper.rb') }

      it 'should raise ConfigurationFileContentError' do
        pattern = Regexp.new('must define OctocatalogDiff::Config.config!')
        expect do
          described_class.load_config_file(filename, @logger)
        end.to raise_error(OctocatalogDiff::API::V1::Config::ConfigurationFileContentError, pattern)
      end

      it 'should log fatal message' do
        exception = nil
        begin
          described_class.load_config_file(filename, @logger)
        rescue OctocatalogDiff::API::V1::Config::ConfigurationFileContentError => exc
          exception = exc
        end
        expect(exception).to be_a_kind_of(OctocatalogDiff::API::V1::Config::ConfigurationFileContentError)
        expect(exception.message).to eq('Configuration must define OctocatalogDiff::Config.config!')
        expect(@logger_str.string).to match(/Configuration must define OctocatalogDiff::Config.config!/)
      end
    end

    context 'with a file that does not define OctocatalogDiff::Config' do
      let(:filename) { OctocatalogDiff::Spec.fixture_path('cli-configs/not-class.rb') }

      it 'should raise ConfigurationFileContentError' do
        pattern = Regexp.new('must define OctocatalogDiff::Config!')
        expect do
          described_class.load_config_file(filename, @logger)
        end.to raise_error(OctocatalogDiff::API::V1::Config::ConfigurationFileContentError, pattern)
      end

      it 'should log fatal message' do
        exception = nil
        begin
          described_class.load_config_file(filename, @logger)
        rescue OctocatalogDiff::API::V1::Config::ConfigurationFileContentError => exc
          exception = exc
        end
        expect(exception).to be_a_kind_of(OctocatalogDiff::API::V1::Config::ConfigurationFileContentError)
        expect(exception.message).to eq('Configuration must define OctocatalogDiff::Config!')
        expect(@logger_str.string).to match(/Configuration must define OctocatalogDiff::Config!/)
      end
    end

    context 'with a file that does not define a hash' do
      let(:filename) { OctocatalogDiff::Spec.fixture_path('cli-configs/not-hash.rb') }

      it 'should raise ConfigurationFileContentError' do
        pattern = Regexp.new('Configuration must be Hash not Array!')
        expect do
          described_class.load_config_file(filename, @logger)
        end.to raise_error(OctocatalogDiff::API::V1::Config::ConfigurationFileContentError, pattern)
      end

      it 'should log fatal message' do
        exception = nil
        begin
          described_class.load_config_file(filename, @logger)
        rescue OctocatalogDiff::API::V1::Config::ConfigurationFileContentError => exc
          exception = exc
        end
        expect(exception).to be_a_kind_of(OctocatalogDiff::API::V1::Config::ConfigurationFileContentError)
        expect(exception.message).to eq('Configuration must be Hash not Array!')
        expect(@logger_str.string).to match(/Configuration must be Hash not Array!/)
      end
    end

    context 'with a valid file' do
      let(:filename) { OctocatalogDiff::Spec.fixture_path('cli-configs/valid.rb') }

      it 'should return the expected settings' do
        result = described_class.load_config_file(filename, @logger)
        answer = { header: :default, hiera_config: 'config/hiera.yaml', hiera_path: 'hieradata' }
        expect(result).to eq(answer)
      end

      it 'should log debug message' do
        described_class.load_config_file(filename, @logger)
        expect(@logger_str.string).to match(/DEBUG -- : Loading octocatalog-diff configuration from/)
      end
    end
  end

  describe '#first_file' do
    before(:each) do
      allow(File).to receive(:'file?') { |x| x =~ /^present/ }
    end

    it 'should accept an empty array and return nil' do
      expect(described_class.first_file([])).to be_nil
    end

    it 'should accept a single missing file and return nil' do
      expect(described_class.first_file(['missing1'])).to be_nil
    end

    it 'should accept a multiple missing files and return nil' do
      expect(described_class.first_file(%w(missing1 missing2 missing3))).to be_nil
    end

    it 'should accept nil in the array and still work' do
      expect(described_class.first_file(['missing1', nil, 'missing2', 'present1'])).to eq('present1')
    end

    it 'should flatten arrays and still work' do
      expect(described_class.first_file(['missing1', [nil, 'missing2'], ['present1']])).to eq('present1')
    end
  end
end
