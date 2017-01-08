# frozen_string_literal: true

# Display source filename and line number for diffs
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:display_source_file_line) do
  has_weight 200

  def parse(parser, options)
    parser.on('--[no-]display-source', 'Show source file and line for each difference') do |x|
      options[:display_source_file_line] = x
    end
  end
end
