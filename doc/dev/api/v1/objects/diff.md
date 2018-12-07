# octocatalog-diff v1 API documentation: OctocatalogDiff::API::V1::Diff

## Overview

`OctocatalogDiff::API::V1::Diff` is an object that represents a single difference between two catalogs.

The return value from the `diffs` computed by the [`catalog-diff`](/doc/dev/api/v1/calls/catalog-diff.md) API call is an Array of these `OctocatalogDiff::API::V1::Diff` objects.

## Methods

#### `#addition?` (Boolean)

Returns true if this diff is an addition (resource exists in new catalog but not old catalog).

#### `#change?` (Boolean)

Returns true if this diff is a change (resource exists in both catalogs but is different between them).

#### `#diff_type` (String)

Returns the type of difference, which is one of the following characters:

- `+` for addition (resource exists in new catalog but not old catalog)
- `-` for removal (resource exists in old catalog but not new catalog)
- `~` or `!` for change (resource exists in both catalogs but is different between them)

See also: `#addition?`, `#change?`, `#removal?`

Note: Internally `~` and `!` represent different types of changes, but when presenting the output, these can generally be considered equivalent.

#### `#new_file` (String)

Returns the filename of the Puppet manifest giving rise to the resource as it exists in the new catalog.

Note that this is a pass-through of information provided in the Puppet catalog, and is not calculated by octocatalog-diff. If the Puppet catalog does not contain this information, this method will return `nil`.

Note also that if the diff represents removal of a resource, this will return `nil`, because the resource does not exist in the new catalog.

#### `#new_line` (String)

Returns the line number within the Puppet manifest giving rise to the resource as it exists in the new catalog. (See `#new_file` for the filename of the Puppet manifest.)

Note that this is a pass-through of information provided in the Puppet catalog, and is not calculated by octocatalog-diff. If the Puppet catalog does not contain this information, this method will return `nil`.

Note also that if the diff represents removal of a resource, this will return `nil`, because the resource does not exist in the new catalog.

#### `#new_location` (Hash)

Returns a hash containing `:file` (equal to `#new_file`) and `:line` (equal to `#new_line`) when either is defined. Returns `nil` if both are undefined.

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

  # Demonstrates structure and new_value
  diff.structure #=> ['parameters', 'content']
  diff.new_value #=> 'This is the NEW FILE!!!!!'
  ```

#### `#old_file` (String)

Returns the filename of the Puppet manifest giving rise to the resource as it exists in the old catalog.

Note that this is a pass-through of information provided in the Puppet catalog, and is not calculated by octocatalog-diff. If the Puppet catalog does not contain this information, this method will return `nil`.

Note also that if the diff represents addition of a resource, this will return `nil`, because the resource does not exist in the old catalog.

#### `#old_line` (String)

Returns the line number within the Puppet manifest giving rise to the resource as it exists in the old catalog. (See `#old_file` for the filename of the Puppet manifest.)

Note that this is a pass-through of information provided in the Puppet catalog, and is not calculated by octocatalog-diff. If the Puppet catalog does not contain this information, this method will return `nil`.

Note also that if the diff represents addition of a resource, this will return `nil`, because the resource does not exist in the old catalog.

#### `#old_location` (Hash)

Returns a hash containing `:file` (equal to `#old_file`) and `:line` (equal to `#old_line`) when either is defined. Returns `nil` if both are undefined.

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
- `diff.type #=> 'File'`

#### `#type` (String)

Returns the type of the resource from the Puppet catalog.

For example, a diff involving `File['/etc/passwd']` would have:

- `diff.title #=> '/etc/passwd'`
- `diff.type #=> 'File'`

Note that the type will be capitalized because Puppet capitalizes this in catalogs.

## Other methods

These methods are available for debugging or development purposes but are not guaranteed to remain consistent between versions:

- `#inspect` (String): Returns inspection of object
- `#raw` (Array): Returns internal array data structure of the "diff"
- `#to_h` (Hash): Returns object as a hash, where keys are above described methods
- `#to_h_with_string_keys` (Hash): Returns object as a hash, where keys are above described methods; keys are strings, not symbols
- `#[]` (Object): Retrieve indexed array elements from raw internal array object
