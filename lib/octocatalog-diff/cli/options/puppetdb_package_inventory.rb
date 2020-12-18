# frozen_string_literal: true

# When pulling facts from PuppetDB in a Puppet Enterprise environment, also include
# the Puppet Enterprise Package Inventory data in the fact results, if available.
# Generally you should not need to specify this, but including the package inventory
# data will produce a more accurate set of input facts for environments using
# package inventory.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:puppetdb_package_inventory) do
  has_weight 150

  def parse(parser, options)
    parser.on('--[no-]puppetdb-package-inventory', 'Include Puppet Enterprise package inventory data, if found') do |x|
      options[:puppetdb_package_inventory] = x
    end
  end
end
