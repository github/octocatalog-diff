# octocatalog-diff v1 API documentation: OctocatalogDiff::API::V1::Diff

## Overview

`OctocatalogDiff::API::V1::Diff` is an object that represents a single difference between two catalogs.

The return value from the `diffs` computed by the [`catalog-diff`](/doc/dev/api/v1/calls/catalog-diff.md) API call is an Array of these `OctocatalogDiff::API::V1::Diff` objects.

## Methods

#### `#addition?` (Boolean)

Returns true if this diff is an addition (resource exists in new catalog but not old catalog).

#### `#change?` (Boolean)

Returns true if this diff is a change (resource exists in both catalogs but is different between them).

#### `#change_type` (String)

Returns the change type of the diff, which is one of the following characters:

- `+` for addition (resource exists in new catalog but not old catalog)
- `-` for removal (resource exists in old catalog but not new catalog)
- `~` or `!` for change (resource exists in both catalogs but is different between them)

See also: `#addition?`, `#change?`, `#removal?`

Note: Internally `~` and `!` represent different types of changes, but when presenting the output, these can generally be considered equivalent.

#### `#new_value` (Object)

Returns the value of the resource from the new catalog.

- If a resource was added, this returns the data structure associated with the resource in the Puppet catalog. For example, if the resource was created as follows in the Puppet catalog, the `new_value` is as indicated.

  ```
  # Resource in New Catalog
  {
    "type": "File",
    "title": "/etc/foo",
    "parameters": {
      "owner": "root",
      "content": "hello new world"
    }
  }

  # Demonstrates new_value
  diff.new_value #=> { 'parameters' => { 'owner' => 'root', 'content' => 'hello new world' } }
  ```

- If a resource was removed, this returns `nil` because there was no value of this resource in the new catalog.

- If a resource was changed, this returns the portion of the data structure that is indicated by the `.structure` method. For example, if the resource existed as follows in both the old and new Puppet catalogs, the `new_value` is as indicated.

  ```
  # Resource in Old Catalog
  {
    "type": "File",
    "title": "/etc/foo",
    "parameters": {
      "owner": "root",
      "content": "This is the old file"
    }
  }

  # Resource in New Catalog
  {
    "type": "File",
    "title": "/etc/foo",
    "parameters": {
      "owner": "root",
      "content": "This is the NEW FILE!!!!!"
    }
  }

  # Demonstrates structure and old_value
  diff.structure #=> ['parameters', 'content']
  diff.old_value #=> 'This is the NEW FILE!!!!!'
  ```

#### `#old_value` (Object)

Returns the value of the resource from the old catalog.

- If a resource was added, this returns `nil` because there was no value of this resource in the old catalog.

- If a resource was removed, this returns the data structure associated with the resource in the Puppet catalog. For example, if the resource existed as follows in the Puppet catalog, the `old_value` is as indicated.

  ```
  # Resource in Old Catalog
  {
    "type": "File",
    "title": "/etc/foo",
    "parameters": {
      "owner": "root",
      "content": "hello old world"
    }
  }

  # Demonstrates old_value
  diff.old_value #=> { 'parameters' => { 'owner' => 'root', 'content' => 'hello old world' } }
  ```

- If a resource was changed, this returns the portion of the data structure that is indicated by the `.structure` method. For example, if the resource existed as follows in both the old and new Puppet catalogs, the `old_value` is as indicated.

  ```
  # Resource in Old Catalog
  {
    "type": "File",
    "title": "/etc/foo",
    "parameters": {
      "owner": "root",
      "content": "This is the old file"
    }
  }

  # Resource in New Catalog
  {
    "type": "File",
    "title": "/etc/foo",
    "parameters": {
      "owner": "root",
      "content": "This is the NEW FILE!!!!!"
    }
  }

  # Demonstrates structure and old_value
  diff.structure #=> ['parameters', 'content']
  diff.old_value #=> 'This is the old file'
  ```

#### `#removal?` (Boolean)

Returns true if this diff is a removal (resource exists in old catalog but not new catalog).

#### `#structure` (Array)

Returns the structure that has been changed, as an array.

When a resource was added or removed, the result is an empty array. That's because all of the parameters and other metadata from the resource exist entirely in one catalog but not the other.

When a resource has changed, one diff is created for each parameter that changed. For example, both the old and new catalogs contain the file resource `/etc/foo` but just the content has changed:

```
# Old
file { '/etc/foo':
  owner   => 'root',
  content => 'This is the old file',
}

# New
file { '/etc/foo':
  owner   => 'root',
  content => 'This is the NEW FILE!!!!!',
}
```

Internally, the Puppet catalog for this resource will look like this in the catalogs (this has been abbreviated a bit for clarity):

```
# Old
{
  "type": "File",
  "title": "/etc/foo",
  "exported": false,
  "parameters": {
    "owner": "root",
    "content": "This is the old file"
  }
}

# New
{
  "type": "File",
  "title": "/etc/foo",
  "exported": false,
  "parameters": {
    "owner": "root",
    "content": "This is the NEW FILE!!!!!"
  }
}
```

One diff will be generated to represent the change to the content of the file (which in the catalog is nested in the 'parameters' hash). The diff will be structured as follows:

```
diff.type #=> 'File'
diff.title #=> '/etc/foo'
diff.structure #=> ['parameters', 'content']
```

#### `#title` (String)

Returns the title of the resource from the Puppet catalog.

For example, a diff involving `File['/etc/passwd']` would have:

- `diff.title #=> '/etc/passwd'`
- `diff.type #=> 'File`

#### `#type` (String)

Returns the type of the resource from the Puppet catalog.

For example, a diff involving `File['/etc/passwd']` would have:

- `diff.title #=> '/etc/passwd'`
- `diff.type #=> 'File`

Note that the type will be capitalized because Puppet capitalizes this in catalogs.
