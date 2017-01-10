# frozen_string_literal: true

# Provide ability to set one or more tags, which will cause catalog-diff
# to ignore any changes for any defined type where this tag is set.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:ignore_tags) do
  has_weight 400

  def parse(parser, options)
    parser.on('--no-ignore-tags', 'Disable ignoring based on tags') do
      if options[:ignore_tags]
        raise ArgumentError, '--no-ignore-tags incompatible with --ignore-tags'
      end
      options[:no_ignore_tags] = true
    end
    parser.on('--ignore-tags STRING1[,STRING2[,...]]', Array, 'Specify tags to ignore') do |x|
      if options[:no_ignore_tags]
        raise ArgumentError, '--ignore-tags incompatible with --no-ignore-tags'
      end
      options[:ignore_tags] ||= []
      options[:ignore_tags].concat x
    end
  end
end
