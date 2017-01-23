# octocatalog-diff v1 API documentation: OctocatalogDiff::API::V1::Override

## Overview

`OctocatalogDiff::API::V1::Override` is an object that represents a user-supplied fact or ENC parameter that will be used when compiling a catalog.

## Constructor

#### `#new(<Hash> { key: <String>, value: <Object> })`

The hash must contain the following keys:

- `:key` (String) - The name of the fact or ENC parameter (e.g. `operatingsystem` or `parameters::fooclass::fooparam`)
- `:value` (?) - The value of the fact or ENC parameter

See also: `#create_from_input`

## Methods

#### `#create_from_input(<String> key=value)` (OctocatalogDiff::API::V1::Override)

Parses the string (see [Overriding facts](/doc/advanced-override-facts.md) for the format to use). Returns a `OctocatalogDiff::API::V1::Override` object with key and value parsed from the string.

#### `#key` (String)

Returns the key as supplied in the constructor.

#### `#value` (?)

Returns the value as supplied in the constructor.
