# octocatalog-diff v1 API documentation: OctocatalogDiff::API::V1::Catalog

## Overview

`OctocatalogDiff::API::V1::Catalog` is an object that represents a compiled catalog.

It wraps the [`OctocatalogDiff::Catalog`](/lib/octocatalog-diff/catalog.rb) object.

This object is the return value from the [`catalog`](/doc/dev/api/v1/calls/catalog.md) API call, and the `to` and `from` catalogs computed by the [`catalog-diff`](/doc/dev/api/v1/calls/catalog-diff.md) API call.

## Methods

#### `#builder` (String)

#### `#compilation_dir` (String)

#### `#error_message` (String)

#### `#puppet_version` (String)

#### `#resource(<Hash>)` (Object)

#### `#resources` (Array&lt;Object&gt;)

#### `#to_json` (String)

#### `#valid?` (Boolean)

## Other methods

These methods are available for debugging or development purposes but are not guaranteed to remain consistent between versions:

- `#to_h` (Hash): Returns hash representation of parsed JSON catalog
- `#raw` (OctocatalogDiff::Catalog): Returns underlying internal catalog object
