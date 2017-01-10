# frozen_string_literal: true

# Toggle on or off the display of data type changes when the string representation
# is the same. For example with this enabled, '42' (the string) and 42 (the integer)
# will be displayed as a difference. With this disabled, this is not displayed as a
# difference.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:display_datatype_changes) do
  has_weight 280

  def parse(parser, options)
    desc = 'Display changes in data type even when strings match'
    parser.on('--[no-]display-datatype-changes', desc) do |x|
      options[:display_datatype_changes] = x
    end
  end
end
