# octocatalog-diff v1 API documentation: OctocatalogDiff::API::V1::Override

## Overview

`OctocatalogDiff::API::V1::Override` is an object that represents a user-supplied fact or ENC parameter that will be used when compiling a catalog.

## Constructor

#### `#new(<Hash>)`

The hash must contain the following keys:

- `:key` (String) - The name of the fact or ENC parameter (e.g. `operatingsystem` or `parameters::fooclass::fooparam`)
- `:value` (?) - The value of the fact or ENC parameter

## Methods

#### `#key` (String)

Returns the key as supplied in the constructor.

#### `#value` (?)

Returns the value as supplied in the constructor.
