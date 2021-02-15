# frozen_string_literal: true

# When a file is specified with `source => 'puppet:///modules/something/foo.txt'`, remove
# the 'source' attribute and populate the 'content' attribute with the text of the file.
# This allows for a diff of the content, rather than a diff of the location, which is
# what is most often desired.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:compare_file_text) do
  has_weight 210

  def parse(parser, options)
    parser.on('--[no-]compare-file-text', 'Compare text, not source location, of file resources') do |x|
      options[:compare_file_text] = x
    end
  end
end

# Sometimes there is a particular file resource for which the file text
# comparison is not desired, while not disabling that option globally. Similar
# to --ignore_tags, it's possible to tag the file resource and exempt it from
# the --compare_file_text checks.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:compare_file_text_ignore_tags) do
  has_weight 415

  def parse(parser, options)
    description = 'Tags that exclude a file resource from text comparison'
    parser.on('--compare-file-text-ignore-tags STRING1[,STRING2[,...]]', Array, description) do |x|
      options[:compare_file_text_ignore_tags] ||= []
      options[:compare_file_text_ignore_tags].concat x
    end
  end
end
