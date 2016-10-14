# Configuring octocatalog-diff to use ENC

If you use an [External Node Classifier (ENC)](https://docs.puppet.com/guides/external_nodes.html) on your Puppet master, you should configure octocatalog-diff to use the same ENC when it compiles catalogs.

Before you start, please understand how octocatalog-diff compiles a catalog:

- It creates a temporary directory (e.g. `/var/tmp/puppet-compile-dir-92347829847`)
- It copies or creates hiera configuration, ENC, PuppetDB configuration, etc., in the temporary directory
- It symlinks `/var/tmp/puppet-compile-dir-92347829847/environments/production` to your code
- It compiles the catalog, based on the temporary directory, for environment=production
- It removes the temporary directory

NOTE: If you are using the built-in node classification in Puppet Enterprise, you don't need to worry about any of this. Instead, please read about [Puppet Enterprise as your ENC](/doc/advanced-pe-enc.md).

## Configuring the path to the ENC

The command line option `--enc PATH` allows you to set the path to your ENC script.

You may specify this as either an absolute or a relative path.

- As a relative path

  octocatalog-diff knows to use a relative path when the supplied path for `--enc` does not start with a `/`.

    ```
    bin/octocatalog-diff --enc config/enc.sh ...
    ```

  The path is relative to a checkout of your Puppet repository. As per the example in the introduction, say that octocatalog-diff is using a temporary directory of `/var/tmp/puppet-compile-dir-92347829847` when compiling a Puppet catalog. With the setting above, it will copy `config/enc.sh` (relative to your Puppet checkout) into the temporary directory.

  If you are specifying the ENC path in the [configuration file](/doc/configuration.md), you will instead set the variable like this:

    ```
    settings[:enc] = 'config/enc.sh'
    ```

  octocatalog-diff will fail if you specify a ENC location that cannot be opened.

- As an absolute path

  octocatalog-diff knows to use a relative path when the supplied path for `--enc` starts with a `/`.

  For example:

    ```
    bin/octocatalog-diff --enc /etc/puppetlabs/puppet/enc.sh ...
    ```

  If you are specifying the ENC path in the [configuration file](/doc/configuration.md), you will instead set the variable like this:

    ```
    settings[:enc] = '/etc/puppetlabs/puppet/enc.sh'
    ```

  Please note that octocatalog-diff will copy the file from the specified location into the compile directory. Since this ENC file is not copied from your Puppet repo, there is no way to compile the "to" and "from" branches using different ENC scripts. Furthermore, you are responsible for getting this file into place on any machine that will run octocatalog-diff.

  We strongly recommend that you version-control your ENC script within your Puppet repository, and use the relative path option described above.

## Executing the ENC

When Puppet runs the ENC, it will do so with one argument (the node name for which you are compiling the catalog).

For example, when compiling the catalog for `some-node.github.net`, Puppet will effectively execute this command:

  ```
  /etc/puppetlabs/puppet/enc.sh some-node.github.net
  ```

Sometimes the ENC script requires credentials or makes other assumptions about the system on which it is running. To be able to run the ENC script on systems other than your Puppet master, you will need to ensure that any such credentials are supplied and other assumptions are met.
