# frozen_string_literal: true

# When a file is specified with `source => 'puppet:///modules/something/foo.txt'`, remove
# the 'source' attribute and populate the 'content' attribute with the text of the file.
# This allows for a diff of the content, rather than a diff of the location, which is
# what is most often desired.
#
# This has historically been a binary option, so --compare-file-text with no argument will
# set this to `true` and --no-compare-file-text will set this to `false`. Note that
# --no-compare-file-text does not accept an argument.
#
# File text comparison will be auto-disabled in circumstances other than compiling and
# comparing two catalogs. To force file text comparison to be enabled at other times,
# set --compare-file-text=force or --compare-file-text=soft. These options allow
# the content of the file to be substituted in to --catalog-only compilations, for example.
# 'force' will raise an exception if the underlying file can't be found; 'soft' won't.
#
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:compare_file_text) do
  has_weight 210

  def parse(parser, options)
    parser.on('--[no-]compare-file-text[=force|soft]', 'Compare text, not source location, of file resources') do |x|
      if x == 'force' || x == 'soft'
        options[:compare_file_text] = x.to_sym
      elsif x == true || x == false
        options[:compare_file_text] = x
      else
        raise OptionParser::NeedlessArgument("needless argument: --compare-file-text=#{x}")
      end
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
