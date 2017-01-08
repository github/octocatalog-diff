# frozen_string_literal: true

# Specify the hostname, or hostname:port, for the Puppet Master.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:puppet_master) do
  has_weight 320

  def parse(parser, options)
    OctocatalogDiff::Cli::Options.option_globally_or_per_branch(
      parser: parser,
      options: options,
      cli_name: 'puppet-master',
      option_name: 'puppet_master',
      desc: 'Hostname or Hostname:PortNumber for Puppet Master'
    )
  end
end
