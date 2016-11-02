# Configuring octocatalog-diff to use Puppet

The most common use of `octocatalog-diff` is to use `puppet` locally to compile catalogs.

In order to successfully use Puppet to compile catalogs:

0. Puppet must be installed on the system.

  It is the goal of `octocatalog-diff` to support Puppet version 3.8 and higher, installed via any means supported by Puppet. This includes the [All-In-One agent package](https://docs.puppet.com/puppet/4.0/reference/release_notes.html#all-in-one-packaging) or installed as a Ruby gem.

  By default, `octocatalog-diff` will look for the Puppet binary in several common system locations.

  For maximum reliability, you can specify the full path to the Puppet binary in the configuration file. For example:

  ```
  ##############################################################################################
  # puppet_binary
  #   This is the full path to the puppet binary on your system. If you don't specify this,
  #   the tool will just run 'puppet' and hope to find it in your path.
  ##############################################################################################

  # settings[:puppet_binary] = '/usr/bin/puppet'
  settings[:puppet_binary] = '/opt/puppetlabs/puppet/bin/puppet'
  ```

0. Applies if you are using [exported resources](https://docs.puppet.com/puppet/latest/reference/lang_exported.html) from PuppetDB (i.e., the octocatalog-diff `--storeconfigs` option enabled):

  Your Puppet installation must have the `puppetdb-termini` feature available. This feature may not be included by default with the Puppet agent package.

  Consult the [Connecting Puppet masters to PuppetDB](https://docs.puppet.com/puppetdb/latest/connect_puppet_master.html#step-1-install-plug-ins) documentation for instructions on installing the `puppetdb-termini` gem.

  :warning: Attention Mac OS users: the [documentation](https://docs.puppet.com/puppet/latest/reference/puppet_collections.html#os-x-systems) states:

  > While the puppet-agent package is the only component of a Puppet Collection available on OS X, you can still use Puppet Collections to ensure the version of package-agent you install is compatible with the Puppet Collection powering your infrastructure.

  Unfortunately this means that you won't be able to enable `--storeconfigs` with the All-In-One Puppet Agent on Mac OS X, unless you manually install a gem-packaged version of `puppetdb-terminus`. The procedure for this is beyond the scope of this documentation.
