# frozen_string_literal: true

# Output format option
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::CatalogDiff::Cli::Options::Option.newoption(:output_format) do
  has_weight 100

  def parse(parser, options)
    valid = %w(text json)
    parser.on('--output-format FORMAT', "Output format: #{valid.join(',')}") do |fmt|
      raise ArgumentError, "Invalid format. Must be one of: #{valid.join(',')}" unless valid.include?(fmt)
      options[:format] = fmt.to_sym
      options[:format] = :color_text if options[:format] == :text && options[:colors]
    end
  end
end
