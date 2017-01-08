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

Note: Internally `~` and `!` represent different types of changes, but when presenting the output, these can generally be considered equivalent.

#### `removal?` (Boolean)

Returns true if this diff is a removal (resource exists in old catalog but not new catalog).
