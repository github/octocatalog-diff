# octocatalog-diff v1 API documentation: catalog

## Overview

`catalog` returns an `OctocatalogDiff::Catalog` object built with the octocatalog-diff compiler, obtained from a Puppet server, or read in from a file. This is analogous to using the `--catalog-only` option with the octocatalog-diff command-line script.

```
catalog_obj = OctocatalogDiff::API::V1.catalog(<Hash>)
#=> OctocatalogDiff::API::V1::Catalog
```

The return value is an [`OctocatalogDiff::API::V1::Catalog`](/doc/dev/api/v1/objects/catalog.md) object.

For an example, see [catalog-builder-local-files.rb](/examples/api/v1/catalog-builder-local-files.rb).

## Parameters

The `catalog` method takes one argument, which is a Hash containing parameters.

The list of parameters here is not exhaustive. The `.catalog` method accepts most parameters described in [Configuration](/doc/configuration.md), [Building catalogs instead of diffing catalogs](/doc/advanced-catalog-only.md), and [Command line options reference](/doc/optionsref.md).

It is also possible to use the parameters from [OctocatalogDiff::API::V1.config](/doc/dev/api/v1/calls/config.md) for the catalog compilation. Simply combine the hash returned by `.config` with any additional keys, and pass the merged hash to the `.catalog` method.

### Global parameters

#### `:logger` (Logger, Optional)

Debugging and informational messages will be logged to this object as the catalog is built.

If no Logger object is passed, these messages will be silently discarded.

#### `:node` (String, Required)

The node name whose catalog is to be compiled or obtained. This should be the fully qualified domain name that matches the node's name as seen in Puppet.

### Computed catalog parameters

#### `:basedir` (String, Optional)

Directory that contains a git repository with the Puppet code. Use in conjunction with `:to_branch` to specify the branch name that should be checked out.

If your Puppet code is not in a git repository, or you already have the branch checked out via some other process, use `:bootstrapped_to_dir` instead.

#### `:bootstrap_script` (String, Optional)

Path to a script to run after checking out the selected branch of Puppet code from the git repository. See [Bootstrapping your Puppet checkout](/doc/advanced-bootstrap.md) for details.

#### `:bootstrapped_to_dir` (String, Optional)

Directory that is already prepared ("bootstrapped") and can have Puppet run against its contents to compile the catalog.

Often this means that you have done the following to this directory:

- Checked out the necessary branch of Puppet code from your version control system
- Installed any third party modules (e.g. with librarian-puppet or r10k)

#### `:enc` (String, Optional)

File path to your External Node Classifier.

See [Configuring octocatalog-diff to use ENC](/doc/configuration-enc.md) for details on using octocatalog-diff with an External Node Classifier.

#### `:fact_file` (String, Optional)

Path to the file that contains the facts for the node whose catalog you are going to compile.

Generally, must either specify the fact file, or [configure octocatalog-diff to use PuppetDB](/doc/configuration-puppetdb.md) to retrieve node facts.

#### `:hiera_config` (String, Optional)

Path to the Hiera configuration file (generally named `hiera.yaml`) for your Puppet installation. Please see [Configuring octocatalog-diff to use Hiera](/doc/configuration-hiera.md) for details on Hiera configuration.

#### `:hiera_path` (String, Optional)

Directory within your Puppet installation where Hiera data is stored. Please see [Configuring octocatalog-diff to use Hiera](/doc/configuration-hiera.md) for details on Hiera configuration.

If your Puppet setup is modeled after the [Puppet control repository template](https://github.com/puppetlabs/control-repo), the correct setting for `:hiera_path` is `'hieradata'`.

#### `:puppet_binary` (String, Required)

Path to the Puppet binary on your system.

Please refer to [Configuring octocatalog-diff to use Puppet](/doc/configuration-puppet.md) for details of connecting octocatalog-diff to your Puppet installation.

#### `:puppetdb_url` (String, Optional)

URL to PuppetDB. See [Configuring octocatalog-diff to use PuppetDB](/doc/configuration-puppetdb.md) for instructions on this setting, and other settings that may be needed in your environment.

#### `:to_branch` (String, Optional)

Branch name in git repository to use for Puppet code. This option must be used in conjunction with `:basedir` so that code can be located.

## Exceptions

The following exceptions may occur during the compilation of a catalog:

- `OctocatalogDiff::Errors::BootstrapError`

  Bootstrapping failed.

- `OctocatalogDiff::Errors::CatalogError`

  Catalog failed to compile. Please note that whenever possible, a `OctocatalogDiff::API::V1::Catalog` object is still constructed for a failed catalog, with `#valid?` returning false.

- `OctocatalogDiff::Errors::GitCheckoutError`

  Git checkout failed.

- `OctocatalogDiff::Errors::PuppetVersionError`

  The version of Puppet could not be determined, generally because the Puppet binary was not found, or does not respond as expected to `puppet version`.

- `OctocatalogDiff::Errors::ReferenceValidationError`

  See [Catalog validation](/doc/advanced-catalog-validation.md).
