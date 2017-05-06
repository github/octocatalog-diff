# frozen_string_literal: true

# Specify a timeout for retrieving a catalog from a Puppet master / Puppet server.
# This timeout is specified in seconds.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:puppet_master_timeout) do
  has_weight 329

  def parse(parser, options)
    OctocatalogDiff::Cli::Options.option_globally_or_per_branch(
      parser: parser,
      options: options,
      cli_name: 'puppet-master-timeout',
      option_name: 'puppet_master_timeout',
      desc: 'Puppet Master catalog retrieval timeout in seconds',
      validator: ->(x) { x.to_i > 0 || raise(ArgumentError, 'Specify timeout as an integer greater than 0') },
      translator: ->(x) { x.to_i }
    )
  end
end
