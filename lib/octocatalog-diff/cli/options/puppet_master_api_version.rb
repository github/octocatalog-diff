# frozen_string_literal: true

# Specify the API version to use for the Puppet Master. This makes it possible to authenticate to a
# version 3.x PuppetMaster by specifying the API version as 2, or for a version 4.x PuppetMaster by
# specifying API version as 3.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:puppet_master_api_version) do
  has_weight 320

  def parse(parser, options)
    OctocatalogDiff::Cli::Options.option_globally_or_per_branch(
      parser: parser,
      options: options,
      cli_name: 'puppet-master-api-version',
      option_name: 'puppet_master_api_version',
      desc: 'Puppet Master API version (2 for Puppet 3.x, 3 for Puppet 4.x)',
      validator: ->(x) { x =~ /^[23]$/ || raise(ArgumentError, 'Only API versions 2 and 3 are supported') },
      translator: ->(x) { x.to_i }
    )
  end
end
