# frozen_string_literal: true

require_relative '../catalog-diff/display'
require_relative '../errors'

module OctocatalogDiff
  class Cli
    # Wrapper around OctocatalogDiff::CatalogDiff::Display to set the options and
    # output to a file or the screen depending on selection.
    class Printer
      # Constructor
      # @param options [Hash] Options from cli/options
      # @param logger [Logger] Logger object
      def initialize(options, logger)
        @options = options
        @logger = logger
      end

      # The method to call externally, passing in diffs. This takes the appropriate action
      # based on options, which is either to write the result into an output file, or print
      # the result on STDOUT. Does not return anything.
      # @param diffs [Array<Diffs>] Array of differences
      # @param from_dir [String] Directory in which "from" catalog was compiled
      # @param to_dir [String] Directory in which "to" catalog was compiled
      def printer(diffs, from_dir = nil, to_dir = nil)
        unless diffs.is_a?(Array)
          raise ArgumentError, "printer() expects an array, not #{diffs.class}"
        end
        display_opts = @options.merge(compilation_from_dir: from_dir, compilation_to_dir: to_dir)
        diff_text = OctocatalogDiff::CatalogDiff::Display.output(diffs, display_opts, @logger)
        if @options[:output_file].nil?
          puts diff_text unless diff_text.empty?
        else
          output_to_file(diff_text)
        end
      end

      private

      # Output to a file, handling errors related to writing files.
      # @param diff_in [String|Array] Text to write to file
      def output_to_file(diff_in)
        diff_text = diff_in.is_a?(Array) ? diff_in.join("\n") : diff_in
        File.open(@options[:output_file], 'w') { |f| f.write(diff_text) }
        @logger.info "Wrote diff to #{@options[:output_file]}"
      rescue Errno::ENOENT, Errno::EACCES, Errno::EISDIR => exc
        @logger.error "Cannot write to #{@options[:output_file]}: #{exc}"
        raise OctocatalogDiff::Errors::PrinterError, "Cannot write to #{@options[:output_file]}: #{exc}"
      end
    end
  end
end
