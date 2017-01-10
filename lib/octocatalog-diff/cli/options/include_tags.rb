# frozen_string_literal: true

# Options used when comparing catalogs - tags are generally ignored; you can un-ignore them.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:include_tags) do
  has_weight 140

  def parse(parser, options)
    parser.on('--[no-]include-tags', 'Include changes to tags in the diff output') do |x|
      options[:include_tags] = x
    end
  end
end
