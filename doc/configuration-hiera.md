# Configuring octocatalog-diff to use Hiera

If you are using Hiera with Puppet, then you must already have a [`hiera.yaml`](https://docs.puppet.com/puppet/latest/reference/config_file_hiera.html) file to configure it. These instructions will guide you through pointing octocatalog-diff at that configuration file.

Before you start, please understand how octocatalog-diff compiles a catalog:

- It creates a temporary directory (e.g. `/var/tmp/puppet-compile-dir-92347829847`)
- It copies or creates hiera configuration, ENC, PuppetDB configuration, etc., in the temporary directory
- It symlinks `/var/tmp/puppet-compile-dir-92347829847/environments/production` to your code
- It compiles the catalog, based on the temporary directory, for environment=production
- It removes the temporary directory

## Configuring the path to hiera.yaml

The command line option `--hiera-config PATH` allows you to set the path to hiera.yaml.

You may specify this as either an absolute or a relative path.

- As a relative path

  octocatalog-diff knows to use a relative path when the supplied path for `--hiera-config` does not start with a `/`.

    ```
    bin/octocatalog-diff --hiera-config config/hiera.yaml ...
    ```

  The path is relative to a checkout of your Puppet repository. As per the example in the introduction, say that octocatalog-diff is using a temporary directory of `/var/tmp/puppet-compile-dir-92347829847` when compiling a Puppet catalog. With the setting above, it will copy `config/hiera.yaml` (relative to your Puppet checkout) into the temporary directory.

  If you use Puppet to manage your hiera.yaml file on Puppet masters, perhaps it is found in one of the modules in your code. In that case, you may use syntax like:

    ```
    bin/octocatalog-diff --hiera-config modules/puppet/files/hiera.yaml ...
    ```

  If you are specifying the hiera.yaml path in the [configuration file](/doc/configuration.md), you will instead set the variable like this:

    ```
    settings[:hiera_config] = 'config/hiera.yaml'
    settings[:hiera_config] = 'modules/puppet/files/hiera.yaml'
    ```

  octocatalog-diff will fail if you specify a hiera configuration location that cannot be opened.

- As an absolute path

  octocatalog-diff knows to use a relative path when the supplied path for `--hiera-config` starts with a `/`.

  For example:

    ```
    bin/octocatalog-diff --hiera-config /etc/puppetlabs/puppet/hiera.yaml ...
    ```

  If you are specifying the hiera.yaml path in the [configuration file](/doc/configuration.md), you will instead set the variable like this:

    ```
    settings[:hiera_config] = '/etc/puppetlabs/puppet/hiera.yaml'
    ```

  Please note that octocatalog-diff will copy the file from the specified location into the compile directory. Since this hiera.yaml file is not copied from your Puppet repo, there is no way to compile the "to" and "from" branches using different hiera.yaml files. Furthermore, you are responsible for getting this file into place on any machine that will run octocatalog-diff.

  We strongly recommend that you version-control your hiera.yaml file within your Puppet repository, and use the relative path option described above.

## Configuring the prefix path to strip

The command line option `--hiera-path-strip PATH` allows you to manipulate directory paths for the JSON or YAML hiera backends. This setting only has an effect on the copy of hiera.yaml that is copied into the temporary compilation directory. This does not make any changes to the actual source hiera.yaml file on your system or in your checkout.

For example, perhaps your production hiera.yaml file has entries such as the following:

```
:backends:
  - yaml
:yaml:
  :datadir: /var/lib/puppet/environments/%{::environment}/hieradata
:hierarchy:
  - servers/%{::fqdn}
  - platform/%{::virtual}
  - datacenter/%{::datacenter}
  - os/%{::operatingsystem}
  - common
```

However, when you run octocatalog-diff, the hiera data will not actually be found in `/var/lib/puppet/environments/production/hieradata`, but rather in a directory called `environments/production/hieradata` relative to the checkout of your Puppet code.

Specifying `--hiera-path-strip PATH` causes octocatalog-diff will rewrite the datadir for the YAML and JSON configuration. In the example above, the correct setting is `--hiera-path-strip /var/lib/puppet`, which will result in the following configuration in the hiera.yaml file:

```
bin/octocatalog-diff --hiera-config environments/production/config/hiera.yaml --hiera-path-strip /var/lib/puppet
```

```
# This is the temporary hiera.yaml file used for octocatalog-diff catalog compilation
:backends:
  - yaml
:yaml:
  :datadir: /var/tmp/puppet-compile-dir-92347829847/environments/%{::environment}/hieradata
:hierarchy:
  - servers/%{::fqdn}
  - platform/%{::virtual}
  - datacenter/%{::datacenter}
  - os/%{::operatingsystem}
  - common
```
