# frozen_string_literal: true

require_relative 'integration_helper'

require 'json'

require OctocatalogDiff::Spec.require_path('/api/v1')
require OctocatalogDiff::Spec.require_path('/cli/printer')

describe 'datatype display integration' do
  let(:diff_array_1) { JSON.parse(OctocatalogDiff::Spec.fixture_read('diffs/datatype-differences.json')) }
  let(:diff_array_2) { JSON.parse(OctocatalogDiff::Spec.fixture_read('diffs/ignore-tags-reversed.json')) }

  before(:each) do
    @logger, @logger_str = OctocatalogDiff::Spec.setup_logger
    @stdout_cache = $stdout
    @stderr_cache = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
  end

  after(:each) do
    $stdout = @stdout_cache
    $stderr = @stderr_cache
  end

  context 'display enabled' do
    let(:options) { { display_datatype_changes: true, format: :text } }
    context 'with datatype changes' do
      it 'should display proper differences and debug messages' do
        subject = OctocatalogDiff::Cli::Printer.new(options, @logger)
        subject.printer(diff_array_1)
        expect($stderr.string).to eq('')
        stdout = $stdout.string.split(/\n/).map(&:strip)
        expect(stdout).to include('File[/tmp/bar] =>')
        expect(stdout).to include('- 755')
        expect(stdout).to include('+ "755"')
        r = Regexp.escape('Adjust display for File::/tmp/bar::parameters::mode: old=755 new="\"755\""')
        expect(@logger_str.string).to match(Regexp.new(r))
      end
    end

    context 'with no datatype changes' do
      it 'should display proper differences and debug messages' do
        subject = OctocatalogDiff::Cli::Printer.new(options, @logger)
        subject.printer(diff_array_2)
        expect($stderr.string).to eq('')
        stdout = $stdout.string.split(/\n/).map(&:strip)
        expect(stdout).to include('Mymodule::Resource2[three] =>')
        expect(stdout).to include('- BAR-NEW')
        expect(stdout).to include('+ BAR-OLD')
        expect(@logger_str.string).not_to match(/Adjust display for/)
      end
    end
  end

  context 'display disabled' do
    let(:options) { { display_datatype_changes: false, format: :text } }
    context 'with datatype changes' do
      it 'should display proper differences and debug messages' do
        subject = OctocatalogDiff::Cli::Printer.new(options, @logger)
        subject.printer(diff_array_1)
        expect($stderr.string).to eq('')
        stdout = $stdout.string.split(/\n/).map(&:strip)
        expect(stdout).to include('+ File[/tmp/foo]')
        expect(stdout).not_to include('File[/tmp/bar] =>')
        expect(@logger_str.string).to match(%r{Adjust display for File::/tmp/bar::parameters::mode: 755 != "755" DELETED})
      end
    end

    context 'with no datatype changes' do
      it 'should display proper differences and debug messages' do
        subject = OctocatalogDiff::Cli::Printer.new(options, @logger)
        subject.printer(diff_array_2)
        expect($stderr.string).to eq('')
        stdout = $stdout.string.split(/\n/).map(&:strip)
        expect(stdout).to include('Mymodule::Resource2[three] =>')
        expect(stdout).to include('- BAR-NEW')
        expect(stdout).to include('+ BAR-OLD')
        expect(@logger_str.string).not_to match(/Adjust display for/)
      end
    end
  end
end
