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

  Your Puppet installation must have the `puppetdb-termini` gem available. This gem may not be included by default with the Puppet agent package.

  Consult the [Connecting Puppet masters to PuppetDB](https://docs.puppet.com/puppetdb/latest/connect_puppet_master.html#step-1-install-plug-ins) documentation for instructions on installing the `puppetdb-termini` gem.
