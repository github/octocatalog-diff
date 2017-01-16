# frozen_string_literal: true

# Transient errors can cause catalog compilation problems. This adds an option to retry
# a failed catalog multiple times before kicking out an error message.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:retry_failed_catalog) do
  has_weight 230

  def parse(parser, options)
    parser.on('--retry-failed-catalog N', OptionParser::DecimalInteger, 'Retry building a failed catalog N times') do |x|
      options[:retry_failed_catalog] = x
    end
  end
end
