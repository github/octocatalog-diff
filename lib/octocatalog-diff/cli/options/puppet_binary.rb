# frozen_string_literal: true

# Set --puppet-binary, --to-puppet-binary, --from-puppet-binary
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:puppet_binary) do
  has_weight 300

  def parse(parser, options)
    OctocatalogDiff::Cli::Options.option_globally_or_per_branch(
      parser: parser,
      options: options,
      cli_name: 'puppet-binary',
      option_name: 'puppet_binary',
      desc: 'Full path to puppet binary'
    )
  end
end
