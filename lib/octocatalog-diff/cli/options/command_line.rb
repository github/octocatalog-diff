# frozen_string_literal: true

# Provide additional command line flags to set when running Puppet to compile catalogs.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:command_line) do
  has_weight 510

  def parse(parser, options)
    OctocatalogDiff::Cli::Options.option_globally_or_per_branch(
      parser: parser,
      options: options,
      cli_name: 'command-line',
      option_name: 'command_line',
      desc: 'Command line arguments',
      datatype: []
    )
  end
end
