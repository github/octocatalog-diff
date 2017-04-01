# Advanced usage

With `--octocatalog-diff` supporting over 75 command line options (and counting), there's a little something for everyone. On this page, we document some interesting use cases that can be accomplished with creative combinations of options.

If you find a creative use of `octocatalog-diff` that we haven't thought of, we encourage you to create a document named `advanced-SOMETHING.md` and link to it from here!

See also:

- [Basic usage](/doc/basic.md) - Common use cases to get you started
- [Command line options reference](/doc/optionsref.md) - A list of *all* the options
- [How to add new command line options](/doc/dev/how-to-add-options.md) - If you'd like to add an option of your own

## Advanced usage documentation

### Building catalogs

- [Bootstrapping your Puppet checkout](/doc/advanced-bootstrap.md)
- [Building catalogs instead of diffing catalogs](/doc/advanced-catalog-only.md)
- [Enabling storeconfigs for exported resources in PuppetDB](/doc/advanced-storeconfigs.md)
- [Fetching catalogs from Puppet Master / PuppetServer](/doc/advanced-puppet-master.md)
- [Overriding ENC parameters](/doc/advanced-override-enc.md)
- [Overriding facts](/doc/advanced-override-facts.md)
- [Puppet Enterprise node classification service](/doc/advanced-pe-enc.md)
- [Using `octocatalog-diff` without git](/doc/advanced-using-without-git.md)
- [Catalog validation](/doc/advanced-catalog-validation.md)
- [Environment setup](/doc/advanced-environments.md)
- [Overriding built-in octocatalog-diff scripts](/doc/advanced-script-override.md)

### Controlling output

- [Ignoring certain changes via command line options](/doc/advanced-ignores.md)
- [Additional output filters](/doc/advanced-filter.md)
- [Dynamic ignoring of changes via tags in Puppet manifests](/doc/advanced-dynamic-ignores.md)
- [Output formats](/doc/advanced-output-formats.md)
- [Useful output hacks](/doc/advanced-output-hacks.md)

### Using `octocatalog-diff` in CI

- [Using `octocatalog-diff` in CI](/doc/advanced-ci.md)

### Using `octocatalog-diff` on your workstation

- [Enabling the cache directory](/doc/advanced-cache-dir.md)

### Using `octocatalog-diff` to help you upgrade

- [Compiling the same catalog with different Puppet versions](/doc/advanced-puppet-versions.md)
- [Enabling the future parser](/doc/advanced-future-parser.md)
