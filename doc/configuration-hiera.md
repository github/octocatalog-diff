# Configuring octocatalog-diff to use Hiera

If you are using Hiera with Puppet, then you must already have a [`hiera.yaml`](https://docs.puppet.com/puppet/latest/reference/config_file_hiera.html) file to configure it. These instructions will guide you through pointing octocatalog-diff at that configuration file.

Before you start, please understand how octocatalog-diff compiles a catalog:

- It creates a temporary directory (e.g. `/var/tmp/puppet-compile-dir-92347829847`)
- It copies or creates hiera configuration, ENC, PuppetDB configuration, etc., in the temporary directory
- It symlinks `/var/tmp/puppet-compile-dir-92347829847/environments/production` to your code
- It compiles the catalog, based on the temporary directory, for environment=production
- It removes the temporary directory

## Configuring the location of hiera.yaml

The command line option `--hiera-config PATH` allows you to set the path to hiera.yaml.

You may specify this as either an absolute or a relative path.

- As a relative path

  octocatalog-diff knows to use a relative path when the supplied path for `--hiera-config` does not start with a `/`.

    ```
    bin/octocatalog-diff --hiera-config hiera.yaml ...
    ```

  The path is relative to a checkout of your Puppet repository. As per the example in the introduction, say that octocatalog-diff is using a temporary directory of `/var/tmp/puppet-compile-dir-92347829847` when compiling a Puppet catalog. With the setting above, it will use the file named `hiera.yaml` that is at the top level
  of your Puppet checkout.

  Perhaps your hiera.yaml file is in a subdirectory of your Puppet checkout. In that case, just use the relative directory path. Be sure not to add a leading `/` though,
  because you don't want octocatalog-diff to treat it as an absolute path. In the following example, suppose you have a top level directory called `config` and your
  `hiera.yaml` file is contained within it. You could then use:

    ```
    bin/octocatalog-diff --hiera-config config/hiera.yaml ...
    ```

  If you are specifying the hiera.yaml path in the [configuration file](/doc/configuration.md), you will instead set the variable like this:

    ```
    settings[:hiera_config] = 'hiera.yaml'
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

## Configuring the directory in your repository in which hiera data files are found

The command line option `--hiera-path PATH` allows you to set the directory path, relative to the checkout of your Puppet repository, of your Hiera YAML/JSON data files.

If you are using the out-of-the-box Puppet Enterprise configuration, or the [Puppet Control Repo template](https://github.com/puppetlabs/control-repo), then the correct setting here is simply 'hieradata'.

You must specify this as a relative path. octocatalog-diff knows to use a relative path when the supplied path for `--hiera-path` does not start with a `/`.

  ```
  bin/octocatalog-diff --hiera-path hieradata ...
  ```

The path is relative to a checkout of your Puppet repository. As per the example in the introduction, say that octocatalog-diff is using a temporary directory of `/var/tmp/puppet-compile-dir-92347829847` when compiling a Puppet catalog. With the setting above, it will look for Hiera data in a directory called `hieradata` that is at the top level
of your Puppet checkout.

If you are specifying the Hiera data path in the [configuration file](/doc/configuration.md), you will instead set the variable like this:

  ```
  settings[:hiera_path] = 'hieradata'
  ```

octocatalog-diff will fail if you specify a path that is not a directory.

## Configuring the prefix path to strip

This is a different, and potentially more complex, alternative to `hiera-path` / `settings[:hiera_path]` described in the prior section. Unless you have a very good reason, you should prefer to use the instructions in the previous sections instead of doing the following.

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

However, when you run octocatalog-diff on a machine that is not a Puppet master, the hiera data will not actually be found in `/etc/puppetlabs/code/environments/production/hieradata`, but rather in a directory called `hiera` relative to the checkout of your Puppet code.

Specifying `--hiera-path-strip PATH` causes octocatalog-diff will munge the datadir for the YAML and JSON configuration. The correct command in this case is now:

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
