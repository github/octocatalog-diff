# Enabling the future parser

The [future parser](https://docs.puppet.com/puppet/3.8/reference/experiments_future.html) is a feature in Puppet 3.8 designed to provide functionally identical to the Puppet language in Puppet 4.0.

You can use these options to enable the future parser for the "from" catalog, the "to" catalog, or both catalogs:

- `--parser-from future` will enable the future parser for the "from" catalog
- `--parser-to future` will enable the future parser for the "to" catalog
- `--parser future` will enable the future parser for both the "from" catalog and the "to" catalog

Note that you can also enable the future parser by creating a file named `environment.conf` in the base directory of your Puppet checkout. When `octocatalog-diff` computes the catalog from this directory, Puppet will read this file and act upon it accordingly.
