# octocatalog-diff v1 API documentation: catalog-diff

## Overview

`catalog-diff` allows you compare two catalogs and obtain the differences between them. Catalogs can be built if necessary.

This is analogous to using the default arguments with the octocatalog-diff command-line script.

```
catalog_diff_result = OctocatalogDiff::API::V1.catalog_diff(

)
```

## Options

**NOTE**: Additional options as described in the [options reference](/doc/optionsref.md) may also have an effect on catalog difference generation.

## Return value

The return value is a structure in the following format:

```
{
  diffs: Array<OctocatalogDiff::API::V1::Diff>,
  from: OctocatalogDiff::API::V1::Catalog,
  to: OctocatalogDiff::API::V1::Catalog
}
```

It is possible to query this object as a hash (e.g. `result[:diffs]`) or using methods (e.g. `result.diffs`).

[Read more about the `OctocatalogDiff::API::V1::Catalog` object](/doc/dev/api/v1/objects/catalog.md)

[Read more about the `OctocatalogDiff::API::V1::Diff` object](/doc/dev/api/v1/objects/diff.md)

## Exceptions
