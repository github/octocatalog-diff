# frozen_string_literal: true

# Quiet option
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:quiet) do
  has_weight 120

  def parse(parser, options)
    parser.on('--[no-]quiet', '-q', 'Quiet (no status messages except errors)') do |x|
      options[:quiet] = x
    end
  end
end
