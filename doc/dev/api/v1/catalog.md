# octocatalog-diff v1 API documentation: catalog

## Overview

`catalog` returns an `OctocatalogDiff::Catalog` object built with the octocatalog-diff compiler, obtained from a Puppet server, or read in from a file. This is analogous to using the `--catalog-only` option with the octocatalog-diff command-line script.

```
catalog_obj = OctocatalogDiff::API::V1.catalog(
  filename: "String",
  logger: Logger,
  test: <true|false>
)
```
