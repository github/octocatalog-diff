# octocatalog-diff v1 API documentation: catalog-diff

## Overview

`catalog-diff` allows you compare two catalogs and obtain the differences between them. Catalogs can be built if necessary.

This is analogous to using the default arguments with the octocatalog-diff command-line script.

```
catalog_diff_result = OctocatalogDiff::API::V1.catalog_diff(<Hash>)
#=> {
  diffs: Array<OctocatalogDiff::API::V1::Diff>,
  from: OctocatalogDiff::API::V1::Catalog,
  to: OctocatalogDiff::API::V1::Catalog
}
```

Return values:
- [`OctocatalogDiff::API::V1::Diff`](/doc/dev/api/v1/objects/diff.md)
- [`OctocatalogDiff::API::V1::Catalog`](/doc/dev/api/v1/objects/catalog.md)

For an example, see [catalog-diff-local-files.rb](/examples/api/v1/catalog-diff-local-files.rb).

## Parameters

The `catalog_diff` method takes one argument, which is a Hash containing parameters.

The list of parameters here is not exhaustive. The `.catalog_diff` method accepts most parameters described in [Configuration](/doc/configuration.md), [Advanced options](/doc/advanced.md), and [Command line options reference](/doc/optionsref.md).

It is also possible to use the parameters from [OctocatalogDiff::API::V1.config](/doc/dev/api/v1/calls/config.md) for the catalog-diff calculation. Simply combine the hash returned by `.config` with any additional keys, and pass the merged hash to the `.catalog_diff` method.

### Global parameters

#### `:logger` (Logger, Optional)

Debugging and informational messages will be logged to this object as the catalogs are built and differences are computed.

If no Logger object is passed, these messages will be silently discarded.

#### `:node` (String, Required)

The node name whose catalogs are to be compiled and differences obtained obtained. This should be the fully qualified domain name that matches the node's name as seen in Puppet.

### Computed catalog parameters

#### `:basedir` (String, Optional)

Directory that contains a git repository with the Puppet code. Use in conjunction with `:to_branch` and `:from_branch` to specify the branch names that should be checked out.

If your Puppet code is not in a git repository, or you already have the branches checked out via some other process, use `:bootstrapped_to_dir` and `:bootstrapped_from_dir` instead.

#### `:bootstrap_script` (String, Optional)

Path to a script to run after checking out the selected branch of Puppet code from the git repository. See [Bootstrapping your Puppet checkout](/doc/advanced-bootstrap.md) for details.

#### `:bootstrapped_to_dir` / `:bootstrapped_from_dir` (String, Optional)

Directories that is already prepared ("bootstrapped") and can have Puppet run against its contents to compile the catalog. `:bootstrapped_to_dir` is used for the "to" catalog, while `:bootstrapped_from_dir` is used for the "from" catalog.

Often this means that you have done the following to this directory:

- Checked out the necessary branch of Puppet code from your version control system
- Installed any third party modules (e.g. with librarian-puppet or r10k)

You may mix and match `:bootstrapped_XXX_dir` and `:basedir` + `:XXX_branch`. For example, you may specify `:bootstrapped_from_dir`, `:basedir`, and `:to_branch`, which will compile the "from" catalog in the bootstrapped "from" directory you specified, and the "to" catalog from the "to_branch" branch of the git repository found in the "basedir".

#### `:enc` / `:to_enc` / `:from_enc` (String, Optional)

File path to your External Node Classifier.

See [Configuring octocatalog-diff to use ENC](/doc/configuration-enc.md) for details on using octocatalog-diff with an External Node Classifier.

In most cases, you will use the `:enc` option to set the ENC for both the "to" and "from" catalogs. In the case that you are comparing two different ENCs, you may use `:to_enc` and/or `:from_enc` as needed.

#### `:fact_file` / `:to_fact_file` / `:from_fact_file` (String, Optional)

Path to the file that contains the facts for the node whose catalog you are going to compile.

Generally, must either specify the fact file, or [configure octocatalog-diff to use PuppetDB](/doc/configuration-puppetdb.md) to retrieve node facts.

In most cases, you will use the `:fact_file` option to set the fact file for both the "to" and "from" catalogs. In the case that you are comparing the results from two different sets of facts, you may use `:to_fact_file` and/or `:from_fact_file` as needed.

#### `:hiera_config` (String, Optional)

Path to the Hiera configuration file (generally named `hiera.yaml`) for your Puppet installation. Please see [Configuring octocatalog-diff to use Hiera](/doc/configuration-hiera.md) for details on Hiera configuration.

#### `:hiera_path` (String, Optional)

Directory within your Puppet installation where Hiera data is stored. Please see [Configuring octocatalog-diff to use Hiera](/doc/configuration-hiera.md) for details on Hiera configuration.

If your Puppet setup is modeled after the [Puppet control repository template](https://github.com/puppetlabs/control-repo), the correct setting for `:hiera_path` is `'hieradata'`.

#### `:puppet_binary` / `:to_puppet_binary` / `:from_puppet_binary` (String, Required)

Path to the Puppet binary on your system.

Please refer to [Configuring octocatalog-diff to use Puppet](/doc/configuration-puppet.md) for details of connecting octocatalog-diff to your Puppet installation.

In most cases, you will use the `:puppet_binary` option to set the Puppet binary for both the "to" and "from" catalogs. In the case that you are comparing the catalogs produced by two different versions of Puppet, you may use `:to_puppet_binary` and/or `:from_puppet_binary` as needed.

#### `:puppetdb_url` (String, Optional)

URL to PuppetDB. See [Configuring octocatalog-diff to use PuppetDB](/doc/configuration-puppetdb.md) for instructions on this setting, and other settings that may be needed in your environment.

#### `:to_branch` / `:from_branch` (String, Optional)

Branch name in git repository to use for Puppet code. Each option must be used in conjunction with `:basedir` so that code can be located.

If you have specified `:bootstrapped_from_dir` or `:from_catalog`, then `:from_branch` will be ignored.

If you have specified `:bootstrapped_to_dir` or `:to_catalog`, then `:from_branch` will be ignored.

#### `:to_catalog` / `:from_catalog` (String, Optional)

If you have already compiled a catalog, set `:to_catalog` and/or `:from_catalog` to the full path to the catalog file.

If you specify a `:XXX_catalog` setting, this will cause `:bootstrapped_XXX_dir` and `:XXX_branch` parameters to be ignored.

### Controlling diffs

#### `:ignore` (Array&lt;Hash&gt;, Optional)

Populating the `:ignore` array filters out matching differences from the overall result using the built-in logic. Please refer to [Ignoring certain changes from the command line](/doc/advanced-ignores.md) for details.

The expected data structure for ignoring a type (e.g. `File` or `Exec`) or title is to construct a hash with a regular expression, like this.

  ```
  # Simple definition, ignores File[/etc/foo]
  [ { type: Regexp.new('\AFile\z'), title: Regexp.new('\A/etc/foo\z') } ]

  # More complicated definition, ignores files in 'tmp' or '.tmp' directories wherever they exist
  [ { type: Regexp.new('\AFile\z'), title: Regexp.new('/\.?tmp/') } ]

  # Ignore all anchors
  [ { type: Regexp.new('\AAnchor\z') } ]

  # Ignore all resources of any type that contain 'foo' in the title
  [ { title: Regexp.new('foo') } ]
  ```

To ignore based on attributes, it is important to understand that each catalog resource is structured as a hash, sometimes with depth greater than 1. An example of Puppet code and the corresponding catalog structure is shown here:

  ```
  # Puppet code
  file { '/etc/hostname':
    owner   => 'root',
    notify  => [ Service['postfix'], Exec['update hostname'] ],
    content => $::fqdn,
  }

  # In the catalog (somewhat abbreviated for brevity)...
  {
    "type": "File",
    "title": "/etc/hostname",
    "parameters": {
      "owner": "root",
      "notify": [
        "Service[postfix]",
        "Exec[update hostname]"
      ],
      "content": "foo-bar.example.com"
    }
  }
  ```

In this case, "owner", "notify", and "content" are nested under "parameters". Internally in octocatalog-diff, this nesting is represented by the "\f" character. (We chose a character that you should have no reason to put in your resource titles or key names.) Thus, the following examples work:

  ```
  # Ignore all changes to the `owner` attribute of a file.
  [ { type: Regexp.new('\AFile\z'), attr: Regexp.new("\\Aparameters\fowner\\z" } ]

  # Ignore changes to `owner` or `group` for a file or an exec.
  [ { type: Regexp.new('\A(File|Exec)\z'), attr: Regexp.new("\\Aparameters\f(owner|group)\\z" } ]
  ```

When using regular expressions, `\f` (form feed character) is used to separate the structure (e.g. `parameters\fowner` refers to the `parameters` hash, `owner` key).

:bulb: Note that `\A` in Ruby matches the beginning of the string and `\z` matches the end, but these are not actual characters. Therefore, if you are using `\A` or `\z` in double quotes (`"`), be sure to heed the examples above and write your expression like: `Regexp.new("\\Aparameters\fowner\\z")`.

#### `:validate_references` (Array&lt;String&gt;, Optional)

Invoke the [catalog validation](/doc/advanced-catalog-validation.md) feature to ensure resources targeted by `before`, `notify`, `require`, and/or `subscribe` exist in the catalog. If this parameter is not defined, no reference validation occurs.

You must set this parameter to an **Array** that contains one or more of the following values:

  - `before`
  - `notify`
  - `require`
  - `subscribe`

## Exceptions

The following exceptions may occur during the compilation of a catalog within the catalog-diff operation:

- `OctocatalogDiff::Errors::BootstrapError`

  Bootstrapping failed.

- `OctocatalogDiff::Errors::CatalogError`

  Catalog failed to compile. Please note that whenever possible, a `OctocatalogDiff::API::V1::Catalog` object is still constructed for a failed catalog, with `#valid?` returning false. It's also possible that the catalog contained broken references -- see [Catalog validation](/doc/advanced-catalog-validation.md).

- `OctocatalogDiff::Errors::GitCheckoutError`

  Git checkout failed.

- `OctocatalogDiff::Errors::PuppetVersionError`

  The version of Puppet could not be determined, generally because the Puppet binary was not found, or does not respond as expected to `puppet version`.
