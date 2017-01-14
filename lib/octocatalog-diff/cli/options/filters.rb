# frozen_string_literal: true

# Specify one or more filters to apply to the results of the catalog difference.
# For a list of available filters and further explanation, please refer to
# <a href="advanced-filter.md">Filtering results</a>.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:filters) do
  has_weight 199

  def parse(parser, options)
    parser.on('--filters FILTER1[,FILTER2[,...]]', Array, 'Filters to apply') do |x|
      options[:filters] ||= []
      options[:filters].concat x

      require_relative '../../catalog-diff/filter'
      options[:filters].each { |filter| OctocatalogDiff::CatalogDiff::Filter.assert_that_filter_exists(filter) }
    end
  end
end
