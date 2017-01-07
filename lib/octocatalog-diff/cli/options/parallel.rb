# frozen_string_literal: true

# Disable or enable parallel processing of catalogs.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:parallel) do
  has_weight 300

  def parse(parser, options)
    parser.on('--[no-]parallel', 'Enable or disable parallel processing') do |x|
      options[:parallel] = x
    end
  end
end
