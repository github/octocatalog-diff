# frozen_string_literal: true

# Debugging option
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:debug) do
  has_weight 110

  def parse(parser, options)
    parser.on('--[no-]debug', '-d', 'Print debugging messages to STDERR') do |x|
      options[:debug] = x
    end
  end
end
