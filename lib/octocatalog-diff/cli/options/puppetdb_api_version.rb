# Specify the API version to use for the PuppetDB. The current values supported are '3' or '4', and '4' is
# the default.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:puppetdb_api_version) do
  has_weight 319

  def parse(parser, options)
    parser.on('--puppetdb-api-version N', OptionParser::DecimalInteger, 'Version of PuppetDB API (3 or 4)') do |x|
      options[:puppetdb_api_version] = x
      raise ArgumentError, 'Only PuppetDB versions 3 and 4 are supported' unless [3, 4].include?(x)
    end
  end
end
