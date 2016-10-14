# Compiling the same catalog with different Puppet versions

`octocatalog-diff` can be a valuable tool when upgrading from one Puppet version to another. By instructing `octocatalog-diff` to compile the "from" catalog with one version of Puppet, and the "to" catalog with another version of Puppet, you can look for changes that arise due to different Puppet versions.

To use this feature, simply point `octocatalog-diff` at the Puppet binary you wish to use for each catalog.

- `--from-puppet-binary DIRECTORY_PATH/puppet` will compile the "from" catalog with the specified Puppet binary
- `--to-puppet-binary DIRECTORY_PATH/puppet` will compile the "to" catalog with the specified Puppet binary
- `--puppet-binary DIRECTORY_PATH/puppet` will compile both catalogs with the specified Puppet binary
