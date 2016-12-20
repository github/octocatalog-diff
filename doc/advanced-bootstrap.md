# Bootstrapping your Puppet checkout

For many implementations of Puppet, an intermediate step is required between checking out code from a repository and having that code be ready to be served via a Puppet Master server. For example, you may need to run `bundler` to install gems or `librarian-puppet` to download Puppet modules. This document will refer to this process -- whatever it may mean for your particular use case -- as *bootstrapping*.

## Bootstrapping with `octocatalog-diff`

Since `octocatalog-diff` integrates closely with your git repository, we provide a mechanism to allow you to perform your bootstrapping between the checkout of the branch and the build of the catalog.

The `--bootstrap-script` option takes a string parameter consisting of either:

  - An absolute path, starting with `/`
  - A path relative to your Puppet checkout, not starting with `/`

For example, if you have a script named `script/bootstrap.sh` in a subdirectory of your Puppet repository, you could instruct `octocatalog-diff` to use this script for bootstrap by specifying:

```
octocatalog-diff --bootstrap-script script/bootstrap.sh ...
```

If you have your bootstrap script at a known location on the system (not stored in your Puppet repository), you can refer to it with an absolute path.

```
octocatalog-diff --bootstrap-script /etc/puppetlabs/repo-bootstrap.sh ...
```

## Configuring bootstrapping via the configuration file

The [example configuration file](/examples/octocatalog-diff.cfg.rb) contains an example setting for the bootstrap script.

```
# settings[:bootstrap_script] = '/etc/puppetlabs/repo-bootstrap.sh' # Absolute path
# settings[:bootstrap_script] = 'script/bootstrap' # Relative path
```

## Bootstrap environment

When the bootstrap script runs, a limited set of environment variables are passed from the shell running octocatalog-diff. Only these variables are set:

- `HOME`
- `PATH`
- `PWD` (set to the base directory of your Puppet checkout)
- `BASEDIR` (as explicitly set with `--basedir` CLI option or `settings[:basedir]` setting)

If you wish to set additional environment variables for your bootstrap script, you may do so via the `--bootstrap-environment VAR=value` command line flag, or by defining `settings[:bootstrap_environment] = { 'VAR' => 'value' }` in your configuration file.

As an example, consider that your bootstrap script is written in Python, and needs the `PYTHONPATH` variable set to `/usr/local/lib/python-custom`. Even if this environment variable is set when octocatalog-diff is run, it will not be available to the bootstrap script. You may supply it via the command line:

```
octocatalog-diff --bootstrap-environment PYTHONPATH=/usr/local/lib/python-custom ...
```

Or you may specify it in your configuration file:

```
settings[:bootstrap_environment] = {
  'PYTHONPATH' => '/usr/local/lib/python-custom'
}
```
