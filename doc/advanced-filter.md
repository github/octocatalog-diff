# Additional output filters

It is possible to enable additional filters for output results via the `--filters` command line option. This command line option accepts a comma-separated list of additional filters, and applies them to the results in the order you specify. The default behavior is not to use any of these filters.

Please note that there are other options to ignore specified diffs, including:

- [Ignoring certain changes via command line options](/doc/advanced-ignores.md)
- [Dynamic ignoring of changes via tags in Puppet manifests](/doc/advanced-dynamic-ignores.md)

Here is the list of available filters and an explanation of each:

- [Absent File](/doc/advanced-filter.md#absent-file) - Ignore parameter changes of a file that is declared to be absent
- [JSON](/doc/advanced-filter.md#json) - Ignore whitespace differences if JSON parses to the same object
- [SingleItemArray](/doc/advanced-filter.md#SingleItemArray) - Ignore differences between object and array containing only that object
- [YAML](/doc/advanced-filter.md#yaml) - Ignore whitespace/comment differences if YAML parses to the same object

## Absent File

#### Usage

```
--filters AbsentFile
```

#### Description

When the `AbsentFile` filter is enabled, if any file is `ensure => absent` in the *new* catalog, then changes to any other parameters will be suppressed.

Consider that a file resource is declared as follows in two catalogs:

```
# Old catalog
file { '/etc/some-file':
  ensure  => present,
  owner   => 'root',
  group   => 'nobody',
  content => 'my content here',
}

# New catalog
file { '/etc/some-file':
  ensure => absent,
  owner  => 'bob',
}
```

Since the practical effect of the new catalog will be to remove the file, it doesn't matter that the owner of the (non-existent) file has changed from 'root' to 'bob', or that the content and group have changed from a string to undefined. Consider the default output without the filter:

```
  File[/etc/some-file] =>
   parameters =>
     ensure =>
      - present
      + absent
     group =>
      - nobody
     owner =>
      - root
      + bob
     content =>
      - my content here
```

Wouldn't it be nice if the meaningless information didn't appear, and all you saw was the transition you actually care about, from present to absent? With `--filters AbsentFile` it does just this:

```
  File[/etc/some-file] =>
   parameters =>
     ensure =>
      - present
      + absent
```

## JSON

#### Usage

```
--filters JSON
```

#### Description

If a file resource has extension `.json` and a difference in its content is observed, JSON objects are constructed from the previous and new values. If these JSON objects are identical, the difference is ignored.

This allows you to ignore changes in whitespace, comments, etc., that are not meaningful to a machine parsing the file. Note that changes to files may still trigger Puppet to restart services even though these changes are not displayed in the octocatalog-diff output.

## Single Item Array

#### Usage

```
--filters SingleItemArray
```

#### Description

When enabling the future parser or upgrading between certain versions of Puppet, the internal structure of the catalog for certain parameters can change as shown in the following example:

```
Old: { "notify": "Service[foo]" }
New: { "notify": [ "Service[foo]" ] }
```

This filter will suppress differences for the value of a parameter when:

- The value in one catalog is an object, AND
- The value in the other catalog is an array containing *only* that same object

## YAML

#### Usage

```
--filters YAML
```

#### Description

If a file resource has extension `.yml` or `.yaml` and a difference in its content is observed, YAML objects are constructed from the previous and new values. If these YAML objects are identical, the difference is ignored.

This allows you to ignore changes in whitespace, comments, etc., that are not meaningful to a machine parsing the file. Please note that by filtering these changes, you are ignoring changes to comments, which may be meaningful to humans. Also, changes to files may still trigger Puppet to restart services even though these changes are not displayed in the octocatalog-diff output.
