# Additional output filters

It is possible to enable additional filters for output results via the `--filters` command line option. This command line option accepts a comma-separated list of additional filters, and applies them to the results in the order you specify. The default behavior is not to use any of these filters.

Please note that there are other options to ignore specified diffs, including:

- [Ignoring certain changes via command line options](/doc/advanced-ignores.md)
- [Dynamic ignoring of changes via tags in Puppet manifests](/doc/advanced-dynamic-ignores.md)

Here is the list of available filters and an explanation of each:

- [YAML](/doc/advanced-filter.md#yaml) - Ignore whitespace/comment differences if YAML parses to the same object

## YAML

#### Usage

```
--filters YAML
```

#### Description

If a file resource has extension `.yml` or `.yaml` and a difference in its content is observed, YAML objects are constructed from the previous and new values. If these YAML objects are identical, the difference is ignored.

This allows you to ignore changes in whitespace, comments, etc., that are not meaningful to a machine parsing the file. Please note that by filtering these changes, you are ignoring changes to comments, which may be meaningful to humans.
