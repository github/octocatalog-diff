# Compare file text

`octocatalog-diff` contains functionality to detect changes in file content for file resources that use the `source` attribute like this:

```
file { '/etc/logrotate.d/my-service.conf':
  source => 'puppet:///modules/logrotate/etc/logrotate.d/my-service.conf',
}
```

When the `source` attribute is used, the catalog contains the value of the attribute (in the example above, `source` = `puppet:///modules/logrotate/etc/logrotate.d/my-service.conf`). However, the catalog does not contain the content of the file. When an agent applies the catalog, the file found on the server or in the code base at `modules/logrotate/file/etc/logrotate.d/my-service.conf` will be installed into `/etc/logrotate.d/my-service.conf`.

If a developer creates a change to this file, the catalog will not indicate this change. This means that so long as the `source` location does not change, any tool analyzing just the catalog would not detect a "diff" resulting from changes in the underlying file itself.

However, since applying the catalog could change the content of a file on the target node, `octocatalog-diff` has a feature that will do the following for any `source => 'puppet:///modules/...'` files:

- Locate the source file in the Puppet code
- Substitute the content of the file into the generated catalog (remove `source` and populate `content`)
- Display the "diff" in the now-populated `content` field

This feature is available only when the catalogs are being compiled from local code. This feature is not available, and will be automatically disabled, when pulling catalogs from PuppetDB or a Puppet server.

Note: In Puppet >= 4.4 there is an option in Puppet itself called "static catalogs" which if enabled will cause the checksum of the file to be included in the catalog. However, the `octocatalog-diff` feature described here is still useful because it can be used to display a "diff" of the change rather than just displaying a "diff" of a checksum.

## Command line options

### `--compare-file-text` and `--no-compare-file-text`

The feature described above is enabled by default, and no special setup is required.

To disable this feature for a specific run, add `--no-compare-file-text` to the command line.

To disable this feature by default, add the following to a [configuration](/doc/configuration.md) file:

```ruby
settings[:compare_file_text] = false
```

If this feature is disabled by default in a configuration file, add `--compare-file-text` to enable the feature for this specific run.

Note that the feature will be automatically disabled, regardless of configuration or command line options, if catalogs are being pulled from PuppetDB or a Puppet server.

### `--compare-file-text=force`

To force the option to be on even in situations when it would be auto-disabled, set the command line argument `--compare-file-text=force`. When the Puppet source code is available, e.g. when compiling a catalog with `--catalog-only`, this will adjust the resulting catalog.

If the Puppet source code is not available, forcing the feature on anyway may end up causing an exception. Use this option at your own risk.

### `--compare-file-text-ignore-tags`

To disable this feature for specific `file` resources, set a tag on the resources for which the comparison is undesired. For example:

```
file { '/etc/logrotate.d/my-service.conf':
  source => 'puppet:///modules/logrotate/etc/logrotate.d/my-service.conf',
}

file { '/etc/logrotate.d/other-service.conf':
  tag    => ['compare-file-text-disable'],
  source => 'puppet:///modules/logrotate/etc/logrotate.d/other-service.conf',
}
```

Inform `octocatalog-diff` of the name of the tag either via the command line (`--compare-file-text-ignore-tags "compare-file-text-disable"`) or via a [configuration](/doc/configuration.md) file:

```ruby
settings[:compare_file_text_ignore_tags] = %w(compare-file-text-disable)
```

With this example setup, the file text would be compared for `/etc/logrotate.d/my-service.conf` but would NOT be compared for `/etc/logrotate.d/other-service.conf`.

Notes:

1. `--compare-file-text-ignore-tags` can take comma-separated arguments if there are multiple tags, e.g.: `--compare-file-text-ignore-tags tag1,tag2`.

1. When defining values in the configuration file, `settings[:compare_file_text_ignore_tags]` must be an array. (The default value is an empty array, `[]`.)

1. "compare-file-text-disable" is used as the name of the tag in the example above, but it is not a magical value. Any valid tag name can be used.

## Notes

1. If the underlying file source cannot be found when building the "to" catalog, an exception will be raised. This will display the resource type and title, the value of `source` that is invalid, and the file name and line number of the Puppet manifest that declared the resource.

1. If the underlying file source cannot be found when building the "from" catalog, no exception will be raised. This behavior allows `octocatalog-diff` to work correctly even if there is a problem in the "from" catalog that is being corrected in the "to" catalog. (Of course, if the underlying file source can't be found in the "to" catalog either, an exception is raised -- see #1.)

1. No processing takes place for file `source` whose values do not start with `puppet:///modules/`.
