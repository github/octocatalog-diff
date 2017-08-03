# Catalog validation

`octocatalog-diff` contains additional functionality to validate catalogs, based on configurable criteria.

Catalog validation features include:

- Validate references: Ensure resources targeted by `before`, `notify`, `require`, and/or `subscribe` exist in the catalog for Puppet 4 and below.

## Validate references

`octocatalog-diff` includes the ability to validate references by ensuring resources targeted by `before`, `notify`, `require`, and/or `subscribe` parameters also exist in the catalog.

Puppet 5 already has this checking built in, so the `--validate-references` option described in this section will be ignored if Puppet 5 is being used. The same exception (`OctocatalogDiff::Errors::CatalogError`) is raised for a missing reference, whether the problem was detected by octocatalog-diff or Puppet 5.

Consider the following Puppet code:

```
file { '/usr/local/bin/some-script.sh':
  source => 'puppet:///modules/test/usr/local/bin/some-script.sh',
  notify => Exec['execute /usr/local/bin/some-script.sh'],
}
```

The catalog for this code would build, whether or not the `exec { 'execute /usr/local/bin/some-script.sh': ... }` resource was part of the catalog. However, when the catalog is applied on the Puppet agent, it would fail if this resource is missing.

With the `--validate-references` command line flag (or the `settings[:validate_references]` [configuration setting](/doc/configuration.md)), you can instruct `octocatalog-diff` to confirm that any resource targeted by a `before`, `notify`, `require`, and `subscribe` parameter actually exists. If the resource is missing from the catalog, an error will be raised, just as if the catalog failed to compile.

The command line argument is demonstrated here:

```
# Validate all references: before,notify,require,subscribe
octocatalog-diff ... --validate-references before,notify,require,subscribe

# Validate some references: only before and require
octocatalog-diff ... --validate-references before,require

# Validate no references
octocatalog-diff ... --no-validate-references
```

By default, no references are validated.

Note as well, when using `octocatalog-diff` to compare two catalogs, the references in the "from" catalog are not checked. The reason for this design decision is as follows: the "from" catalog is generally what is considered to be stable and is perhaps already deployed, so it adds no value (and perhaps inhibits the ability to develop further) if `octocatalog-diff` fails just because references in the "from" catalog are broken.
