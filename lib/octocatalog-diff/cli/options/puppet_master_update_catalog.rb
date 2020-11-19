# frozen_string_literal: true

# Specify if, when using the Puppetserver v4 catalog API, the Puppetserver should
# update the catalog in PuppetDB.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:puppet_master_update_catalog) do
  has_weight 320

  def parse(parser, options)
    OctocatalogDiff::Cli::Options.option_globally_or_per_branch(
      parser: parser,
      options: options,
      datatype: false,
      cli_name: 'puppet-master-update-catalog',
      option_name: 'puppet_master_update_catalog',
      desc: 'Update catalog in PuppetDB when using Puppetmaster API version 4'
    )
  end
end
