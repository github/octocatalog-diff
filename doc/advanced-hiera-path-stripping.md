# Configuring octocatalog-diff to use Hiera path stripping

This is a different, and potentially more complex, alternative to `--hiera-path` / `settings[:hiera_path]` described in the [Configuring octocatalog-diff to use Hiera](/doc/configuration-hiera.md) document. Unless you have a very good reason, you should prefer to use the instructions in that document instead of using the more complicated option that is described herein.

The command line option `--hiera-path-strip PATH` allows you to manipulate directory paths for the JSON or YAML hiera backends. This setting only has an effect on the copy of hiera.yaml that is copied into the temporary compilation directory. This does not make any changes to the actual source hiera.yaml file on your system or in your checkout.

For example, perhaps your production hiera.yaml file has entries such as the following:

```
---
:backends:
  - yaml
:hierarchy:
  - "nodes/%{::trusted.certname}"
  - common

:yaml:
  :datadir: /etc/puppetlabs/code/environments/%{environment}/hieradata
```

However, when you run octocatalog-diff on a machine that is not a Puppet master, the hiera data will not actually be found in `/etc/puppetlabs/code/environments/production/hieradata`, but rather in a directory called `hieradata` relative to the checkout of your Puppet code.

Specifying `--hiera-path-strip PATH` causes octocatalog-diff to munge the datadir for the YAML and JSON configuration. The correct command in this case is now:

```
bin/octocatalog-diff --hiera-config hiera.yaml --hiera-path-strip /etc/puppetlabs/code
```

```
---
:backends:
  - yaml
:hierarchy:
  - "nodes/%{::trusted.certname}"
  - common

:yaml:
  :datadir: /var/tmp/puppet-compile-dir-92347829847/environments/%{environment}/hieradata
```

:warning: Be sure that you do NOT include a trailing slash on `--hiera-path-strip` or `settings[:hiera_path_strip]`.
