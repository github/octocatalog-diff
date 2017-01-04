# frozen_string_literal: true

require_relative '../../spec_helper'
require OctocatalogDiff::Spec.require_path('/cli/printer')

require 'json'
require 'tempfile'

describe OctocatalogDiff::Cli::Printer do
  describe '#printer' do
    before(:all) do
      @diff = JSON.parse(File.read(OctocatalogDiff::Spec.fixture_path('diffs/catalog-1-vs-catalog-2.json')))
    end

    it 'should write to a file when options output_file is specified' do
      begin
        # Set up the tempfile to output to.
        tmpfile = Tempfile.new(['catalog-diff-output', '.txt'])
        tmpfile.close

        # Set up the options. In this case, just the path to the tempfile.
        opts = {
          output_file: tmpfile.path,
          format: :text
        }

        # Set up the logger. In this case, it needs to receive :info from the success
        # message observed when writing the file.
        logger, logger_str = OctocatalogDiff::Spec.setup_logger

        # Run the method. Make sure it doesn't print anything to STDOUT.
        testobj = OctocatalogDiff::Cli::Printer.new(opts, logger)
        expect do
          _result = testobj.printer(@diff)
        end.not_to output.to_stdout

        # Make sure the content is correct. This is not intended to be a detailed test of the output
        # format, since that is tested elsewhere. Just match a string that is known to be in the output.
        content = File.read(tmpfile.path)
        expect(content).to match(/Class\[Openssl::Package\]/)

        # Make sure log messages are correct
        expect(logger_str.string).to match(/DEBUG -- : Generating non-colored text output/)
        expect(logger_str.string).to match(/INFO -- : Wrote diff to/)
        expect(logger_str.string).to match(/DEBUG -- : Changed resources: 8/)
      ensure
        FileUtils.rm_f tmpfile.path if File.exist?(tmpfile.path)
      end
    end

    it 'should raise an error if it cannot write to a file' do
      # Set up the options. In this case, an invalid path.
      opts = {
        output_file: '/x/x/x/x/x/x/x/x/x/x/x/x/x/x/x/x/x/x/xx/x/x/x/x/x/x/x/xx/xx.x',
        format: :text
      }

      # Set up the logger. In this case, it needs to receive :error when the file cannot be written.
      logger, logger_str = OctocatalogDiff::Spec.setup_logger

      # Run the method. Make sure it raises the error.
      testobj = OctocatalogDiff::Cli::Printer.new(opts, logger)
      expect do
        _result = testobj.printer(@diff)
      end.to raise_error(OctocatalogDiff::Cli::Printer::PrinterError)

      # Make sure log messages are correct
      expect(logger_str.string).to match(/DEBUG -- : Generating non-colored text output/)
      expect(logger_str.string).to match(%r{ERROR -- : Cannot write to /x/x/x/x/x})
    end

    it 'should print out to console if no output file is given' do
      # Set up the options. In this case, no output file is provided.
      opts = {
        format: :color_text
      }

      # Set up the logger.
      logger, logger_str = OctocatalogDiff::Spec.setup_logger

      # Run the method. Make sure it prints to STDOUT.
      testobj = OctocatalogDiff::Cli::Printer.new(opts, logger)
      expect do
        _result = testobj.printer(@diff)
      end.to output(/Class\[Openssl::Package\]/).to_stdout

      # Make sure log messages are correct
      expect(logger_str.string).to match(/DEBUG -- : Generating colored text output/)
      expect(logger_str.string).to match(/DEBUG -- : Changed resources: 8/)
    end
  end
end
