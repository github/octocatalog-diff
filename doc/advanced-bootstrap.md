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
