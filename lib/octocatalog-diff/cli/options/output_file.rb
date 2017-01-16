# frozen_string_literal: true

# Output file option
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:output_file) do
  has_weight 90

  def parse(parser, options)
    parser.on('--output-file FILENAME', '-o', 'Output results into FILENAME') do |filename|
      path = File.absolute_path(filename)
      options[:output_file] = path
      options[:format] = :text
      options[:colors] = false
    end
  end
end
