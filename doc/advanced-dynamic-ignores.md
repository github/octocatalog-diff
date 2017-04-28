# Dynamic Ignoring Based On Tags

Using the `--ignore-tags` command line option, it is possible to ignore all resources with particular Puppet tags. This allows dynamic ignoring of wrappers or other resources that are not of interest.

NOTE: This option is separate and distinct from `--include-tags`, which controls whether differences in tags themselves will appear as a difference. For more on `--include-tags`, consult the [options reference](/doc/optionsref.md).

## Getting Started

To use ignored tags, you first need to decide what the name of your tag will be. The standard is `ignored_octocatalog_diff`.

When you are writing Puppet code, you can tag a particular resource as being of no interest to `octocatalog-diff`.

```
class foo {
  file { '/etc/foo':
    ensure => file,
    source => 'puppet:///modules/foo/etc/foo',
    tag    => [ 'ignored_octocatalog_diff' ],
  }
}
```

You can also tag a resource that is a custom defined type.

```
class foo {
  foo::customfile { '/etc/foo':
    source => 'puppet:///modules/foo/etc/foo',
    tag    => [ 'ignored_octocatalog_diff__foo__customfile' ],
  }
}

define foo::customfile (
  String $source,
) {
  file { $name:
    ensure => file,
    source => $source,
  }
}
```

Finally, you can tag an entire defined type.

```
class foo {
  foo::customfile { '/etc/foo':
    source => 'puppet:///modules/foo/etc/foo',
  }
}

define foo::customfile (
  String $source,
) {
  tag 'ignored_octocatalog_diff__foo__customfile'

  file { $name:
    ensure => file,
    source => $source,
  }
}
```

When octocatalog-diff processes the ignore-tag, it will ignore a resource if either of the following is true:

- The resource has a tag exactly matching the ignore-tag. For the default tag name, this means a resource has the tag `ignored_octocatalog_diff`.

- The resource has a tag that matches the ignore-tag joined to the type with two underscores (where the type is in lower case and non-alphanumeric characters are replaced with underscores). This means that when the ignore-tag is `ignored_octocatalog_diff`, octocatalog-diff would ignore a file resource with a tag of `ignored_octocatalog_diff__file`, but would not ignore an exec resource with that same tag.

The reasoning for the second syntax is explained in [caveats](#caveats).

## Usage

To ignore one tag:

```
octocatalog-diff --ignore-tags ignored_octocatalog_diff ...
```

To ignore multiple tags:

```
octocatalog-diff --ignore-tags ignored_octocatalog_diff --ignore-tags second_tag ...
```

To disable all ignoring of tags:

```
octocatalog-diff --no-ignore-tags ...
```

## Caveats

When you tag a resource or defined type, Puppet will propagate that tag to *all* descendent resources.

In this example, the tag `ignored_octocatalog_diff__foo__customfile` is propagated to the `foo::customfile` resource and to the file resource. However, octocatalog-diff will ignore only the `foo::customfile`, and will not ignore the file resource.

```
define foo::customfile (
  String $source,
) {
  tag 'ignored_octocatalog_diff__foo__customfile'

  file { $name:
    ensure => file,
    source => $source,
  }
}
```

:warning: If you were to do the following, not only would changes to `foo::customfile` parameters be ignored, but changes to the file resource would be ignored as well! That's because both `foo::customfile` and the file would have the tag `ignored_octocatalog_diff`, because the tag set in the defined type propagates to all descendent resources.

```
define foo::customfile (
  String $source,
) {
  # DO NOT DO THIS!!!
  tag 'ignored_octocatalog_diff'

  file { $name:
    ensure => file,
    source => $source,
  }
}
```
