# frozen_string_literal: true

# Options used when comparing catalogs - set ignored changes.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:ignore) do
  has_weight 130

  def parse(parser, options)
    descriptive_text = 'More resources to ignore in format type[title]'
    parser.on('--ignore "Type1[Title1],Type2[Title2],..."', Array, descriptive_text) do |res|
      options[:ignore] ||= []
      res.each do |item|
        if item =~ /\A(.+?)\[(.+)\](.+)/
          h = { type: Regexp.last_match(1), title: Regexp.last_match(2) }
          h[:attr] = Regexp.last_match(3).gsub(/(\\f|::)/, "\f")
          options[:ignore] << h
        elsif item =~ /^(.+?)\[(.+)\]$/
          options[:ignore] << { type: Regexp.last_match(1), title: Regexp.last_match(2) }
        else
          raise ArgumentError, "Ignore #{item} must be in Type[Title] or Type[Title]::Attribute format!"
        end
      end
    end
  end
end
