# frozen_string_literal: true

# Specify the environment to use when compiling the catalog. This is useful only in conjunction
# with `--preserve-environments`.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:environment) do
  has_weight 502

  def parse(parser, options)
    OctocatalogDiff::Cli::Options.option_globally_or_per_branch(
      parser: parser,
      options: options,
      cli_name: 'environment',
      option_name: 'environment',
      desc: 'Environment for catalog compilation'
    )
  end
end
