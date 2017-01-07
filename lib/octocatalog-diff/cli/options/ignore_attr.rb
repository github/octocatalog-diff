# frozen_string_literal: true

# Specify attributes to ignore
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:ignore_attr) do
  has_weight 190

  def parse(parser, options)
    parser.on('--ignore-attr "attr1,attr2,..."', Array, 'Attributes to ignore') do |res|
      options[:ignore] ||= []
      res.each do |item|
        item_subst = item.gsub(/(\\f|::)/, "\f")
        options[:ignore] << { attr: item_subst }
      end
    end
  end
end
