# frozen_string_literal: true

# Configures using the Longest common subsequence (LCS) algorithm to determine differences in arrays
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:use_lcs) do
  has_weight 250

  def parse(parser, options)
    parser.on('--[no-]use-lcs', 'Use the LCS algorithm to determine differences in arrays') do |x|
      options[:use_lcs] = x
    end
  end
end
