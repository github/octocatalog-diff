# frozen_string_literal: true

# When set, --catalog-only will only compile the catalog for the 'to' branch, and skip any
# diffing activity. The catalog will be printed to STDOUT or written to the output file.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:catalog_only) do
  has_weight 290

  def parse(parser, options)
    desc = 'Only compile the catalog for the "to" branch but do not diff'
    parser.on('--[no-]catalog-only', desc) do |x|
      options[:catalog_only] = x
    end
  end
end
