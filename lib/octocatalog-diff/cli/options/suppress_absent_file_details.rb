# frozen_string_literal: true

# If enabled, this option will suppress changes to certain attributes of a file, if the
# file is specified to be 'absent' in the target catalog. Suppressed changes in this case
# include user, group, mode, and content, because a removed file has none of those.
# <i>This option is DEPRECATED; please use <code>--filters AbsentFile</code> instead.</i>
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:suppress_absent_file_details) do
  has_weight 600

  def parse(parser, options)
    parser.on('--[no-]suppress-absent-file-details', 'Suppress certain attributes of absent files') do |x|
      options[:suppress_absent_file_details] = x
    end
  end
end
