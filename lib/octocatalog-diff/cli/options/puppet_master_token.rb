# frozen_string_literal: true

# Specify a PE RBAC token used to authenticate to Puppetserver for v4
# catalog API calls.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:puppet_master_token) do
  has_weight 310

  def parse(parser, options)
    OctocatalogDiff::Cli::Options.option_globally_or_per_branch(
      parser: parser,
      options: options,
      datatype: '',
      cli_name: 'puppet-master-token',
      option_name: 'puppet_master_token',
      desc: 'PE RBAC token to authenticate to the Puppetserver API v4'
    )
  end
end
