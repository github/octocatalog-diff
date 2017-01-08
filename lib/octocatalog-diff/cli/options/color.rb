# frozen_string_literal: true

# Color printing option
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:color) do
  has_weight 80

  def parse(parser, options)
    parser.on('--[no-]color', 'Enable/disable colors in output') do |color|
      options[:colors] = color
      options[:format] = color ? :color_text : :text
    end
  end
end
