# Configuring octocatalog-diff to use Hiera

## Hiera 5

Hiera 5 is included with Puppet 4.9 and higher.

If there is a `hiera.yaml` file in the base directory of the environment that is in hiera 5 format, and you are running Puppet 4.9 or higher, then that file will be recognized by Puppet (and therefore, by octocatalog-diff). There is no special configuration for octocatalog-diff needed to make this work. Similarly, there is no command line option or setting to changed this behavior, because there is no corresponding option to change Puppet's behavior.

If you are running Puppet 4.8 or lower, then the `hiera.yaml` file in the base directory of the environment will be ignored (unless you use `--hiera-config` to specify it as your global configuration file).

If you have no global hiera configuration and you wish to rely on a `hiera.yaml` file in the base directory of your environment, make sure that you are *not* using any of the following command line options or [configuration settings](/doc/configuration.md):

- `--hiera-path` or `settings[:hiera_path]`
- `--hiera-path-strip` or `settings[:hiera_path_strip]`
- `--hiera-config` or `settings[:hiera_config]`

There is more information about Hiera 5 in Puppet's documentation:

- [Enable the environment layer for existing Hiera data](https://puppet.com/docs/puppet/5.3/hiera_migrate_environments.html)

## Hiera global configuration

If you are using Hiera 5 with a global configuration, or you are using Hiera 3 or before, then you must already have a [`hiera.yaml`](https://docs.puppet.com/puppet/latest/reference/config_file_hiera.html) file to configure it. These instructions will guide you through pointing octocatalog-diff at that configuration file.

octocatalog-diff will automatically determine the version of your Hiera configuration file and treat it accordingly. (Hiera 5 configuration files are identified as such by a `version: 5` line in the file itself.)

Before you start, please understand how octocatalog-diff compiles a catalog:

- It creates a temporary directory (e.g. `/var/tmp/puppet-compile-dir-92347829847`)
- It copies or creates hiera configuration, ENC, PuppetDB configuration, etc., in the temporary directory
- It symlinks `/var/tmp/puppet-compile-dir-92347829847/environments/production` to your code
- It compiles the catalog, based on the temporary directory, for environment=production
- It removes the temporary directory

### Configuring the location of global hiera.yaml

The command line option `--hiera-config PATH` allows you to set the path to the global hiera.yaml.

You may specify this as either an absolute or a relative path.

- As a relative path

  octocatalog-diff knows to use a relative path when the supplied path for `--hiera-config` does not start with a `/`.

    ```
    bin/octocatalog-diff --hiera-config hiera.yaml ...
    ```

  The path is relative to a checkout of your Puppet repository. With the setting above, it will use the file named `hiera.yaml` that is at the top level of your Puppet checkout.

  Perhaps your hiera.yaml file is in a subdirectory of your Puppet checkout. In that case, just use the relative directory path. Be sure not to add a leading `/` though, because you don't want octocatalog-diff to treat it as an absolute path. In the following example, suppose you have a top level directory called `config` and your `hiera.yaml` file is contained within it. You could then use:

    ```
    bin/octocatalog-diff --hiera-config config/hiera.yaml ...
    ```

  If you are specifying the hiera.yaml path in the [configuration file](/doc/configuration.md), you will instead set the variable like this:

    ```
    settings[:hiera_config] = 'hiera.yaml'
    (or)
    settings[:hiera_config] = 'config/hiera.yaml'
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

  Please note that octocatalog-diff will copy the file from the specified location into the compile directory. Since this hiera.yaml file is not copied from your Puppet repo, there is no way to compile the "to" and "from" branches using different hiera.yaml files. Furthermore, you are responsible for getting this file into place on any machine that will run octocatalog-diff. An absolute path may make octocatalog-diff work correctly on your Puppet master servers, but the structure may differ on other machines where you wish to run the utility.

  We strongly recommend that you version-control your hiera.yaml file within your Puppet repository, and use the relative path option described above.

### Configuring the directory in your repository in which hiera data files are found

The command line option `--hiera-path PATH` allows you to set the directory path, relative to the checkout of your Puppet repository, of your Hiera YAML/JSON data files.

If you are using the out-of-the-box Puppet Enterprise configuration, or the [Puppet Control Repo template](https://github.com/puppetlabs/control-repo), then the correct setting here is simply 'hieradata'.

You must specify this as a relative path. octocatalog-diff knows to use a relative path when the supplied path for `--hiera-path` does not start with a `/`.

  ```
  bin/octocatalog-diff --hiera-path hieradata ...
  ```

The path is relative to a checkout of your Puppet repository. With the setting above, it will look for Hiera data in a directory called `hieradata` that is at the top level
of your Puppet checkout.

If you are specifying the Hiera data path in the [configuration file](/doc/configuration.md), you will instead set the variable like this:

  ```
  settings[:hiera_path] = 'hieradata'
  ```

octocatalog-diff will fail if you specify a path that is not a directory.

### Configuring the prefix path to strip

This is a different, and potentially more complex, alternative to `--hiera-path` / `settings[:hiera_path]` described in the prior section. Unless you have a very good reason, you should prefer to use the instructions above.

If you need to use the more complex path strip alternative, see: [Configuring octocatalog-diff to use Hiera path stripping](/doc/advanced-hiera-path-stripping.md).
