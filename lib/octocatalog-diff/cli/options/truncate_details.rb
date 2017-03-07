# frozen_string_literal: true

# When using `--display-detail-add` by default the details of any field will be truncated
# at 80 characters. Specify `--no-truncate-details` to display the full output. This option
# has no effect when `--display-detail-add` is not used.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:truncate_details) do
  has_weight 251

  def parse(parser, options)
    parser.on('--[no-]truncate-details', 'Truncate details with --display-detail-add') do |x|
      options[:truncate_details] = x
    end
  end
end
