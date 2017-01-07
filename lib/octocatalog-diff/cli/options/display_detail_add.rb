# frozen_string_literal: true

# Provide ability to display details of 'added' resources in the output.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:display_detail_add) do
  has_weight 250

  def parse(parser, options)
    parser.on('--[no-]display-detail-add', 'Display parameters and other details for added resources') do |x|
      options[:display_detail_add] = x
    end
  end
end
