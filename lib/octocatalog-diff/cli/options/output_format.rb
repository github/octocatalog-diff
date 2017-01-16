# frozen_string_literal: true

# Output format option. 'text' is human readable text, 'json' is an array of differences
# identified by human readable keys (the preferred octocatalog-diff 1.x format), and 'legacy_json' is an
# array of differences, where each difference is an array (the octocatalog-diff 0.x format).
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:output_format) do
  has_weight 100

  def parse(parser, options)
    valid = %w(text json legacy_json)
    parser.on('--output-format FORMAT', "Output format: #{valid.join(',')}") do |fmt|
      raise ArgumentError, "Invalid format. Must be one of: #{valid.join(',')}" unless valid.include?(fmt)
      options[:format] = fmt.to_sym
      options[:format] = :color_text if options[:format] == :text && options[:colors]
    end
  end
end
