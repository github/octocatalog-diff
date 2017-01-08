# octocatalog-diff v1 API documentation: catalog

## Overview

`catalog` returns an `OctocatalogDiff::Catalog` object built with the octocatalog-diff compiler, obtained from a Puppet server, or read in from a file. This is analogous to using the `--catalog-only` option with the octocatalog-diff command-line script.

```
catalog_obj = OctocatalogDiff::API::V1.catalog(

)
```

## Options


**NOTE**: Additional options as described in the [options reference](/doc/optionsref.md) may also have an effect on catalog generation.

## Return value

The return value is an [`OctocatalogDiff::API::V1::Catalog`](/doc/dev/api/v1/objects/catalog.md) object.

## Exceptions
