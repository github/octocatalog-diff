# Configuration

`octocatalog-diff` may require configuration to work correctly with your Puppet setup.

0. Download the [sample configuration file](https://raw.githubusercontent.com/github/octocatalog-diff/master/examples/octocatalog-diff.cfg.rb) and save it into one of the following directories.

  - In the base directory of your Puppet repository checkout (i.e., your current working directory):

    ```
    .octocatalog-diff.cfg.rb
    ```

  - In your home directory:

    ```
    $HOME/.octocatalog-diff.cfg.rb
    ```

  - In one of the following system locations:

    ```
    /usr/local/etc/octocatalog-diff.cfg.rb
    /opt/puppetlabs/octocatalog-diff/octocatalog-diff.cfg.rb
    /etc/octocatalog-diff.cfg.rb
    ```

  Note: If more than one of the above files is present, the first one found will be used (proceeding from top to bottom in that list). If you set an environment variable `OCTOCATALOG_DIFF_CONFIG_FILE` that will supersede all of the above paths, and allow you to specify the configuration file location however you wish.

0. Open the file in a text editor, and follow the comments within the file to guide yourself through configuration. The configuration file is pure ruby, allowing substantial flexibility in the configuration.

  To be minimally functional, you will almost certainly need to define at least the following settings:

  - `settings[:hiera_config]` as the absolute or relative path to your hiera configuration file
  - `settings[:hiera_path_strip]` as the prefix to strip when munging the hiera configuration file
  - `settings[:puppetdb_url]` as the URL to your PuppetDB instance so facts can be obtained

  For more information on these settings:

  - [Configuring octocatalog-diff to use Hiera](/doc/configuration-hiera.md)
  - [Configuring octocatalog-diff to use ENC](/doc/configuration-enc.md)
  - [Configuring octocatalog-diff to use PuppetDB](/doc/configuration-puppetdb.md)
  - [Configuring octocatalog-diff to use Puppet](/doc/configuration-puppet.md)

0. Test the configuration, which will indicate the location of the configuration file and validate the contents thereof.

  ```
  octocatalog-diff --config-test
  ```

  Note: If you [installed](/doc/installation.md) octocatalog-diff as a gem, the `octocatalog-diff` binary should be in your $PATH and the above command should work correctly. If you installed in a different way, you may need to provide the full path to where the `octocatalog-diff` binary was actually installed.

Now that you have entered your configuration and confirmed proper reading of your configuration file, proceed to [Basic usage](/doc/basic.md) to see if it works!
