# octocatalog-diff v1 API documentation: OctocatalogDiff::API::V1::FactOverride

## Overview

`OctocatalogDiff::API::V1::FactOverride` is an object that represents a user-supplied fact that will be used when compiling a catalog.

## Constructor

#### `#new(<Hash>)`

The hash must contain the following keys:

- `:fact_name` (String) - The name of the fact (e.g. `operatingsystem` or `ipaddress`)
- `:value` (?) - The value of the fact

## Methods

#### `#fact_name` (String)

Returns the name of the fact as supplied in the constructor.

#### `#value` (?)

Returns the value of the fact as supplied in the constructor.
