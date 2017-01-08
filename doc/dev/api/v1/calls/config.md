# octocatalog-diff v1 API documentation: config

## Overview

`config` reads and parses an [octocatalog-diff configuration file](/doc/configuration.md).

```
options = OctocatalogDiff::API::V1.config(
  filename: "String",
  logger: Logger,
  test: <true|false>
)
```

## Options

- **`:filename`** (String, optional): Full path to configuration file to read. If not provided, the configuration file will be searched as described in [Configuration](/doc/configuration.md).

- **`:logger`** (Logger, optional): Logger object. If provided, debug messages and fatal errors will be logged to this object.

- **`:test`** (Boolean, optional): Test mode, defaults to false. If true, the value of the configuration settings will be logged to the logger (with priority DEBUG) and an exception will be raised if the configuration file cannot be located.

## Return value

If the configuration file is located and valid, the return value is a Hash consisting of the options defined in the configuration file.

If the configuration file cannot be found, the return value is an empty Hash (`{}`). Except, with `:test => true`, an exception will be raised.

## Exceptions

- `OctocatalogDiff::Errors::ConfigurationFileContentError`

  Raised if the configuration file could not be evaluated. A more specific error message will help identify the cause. Possible causes include the file not being valid ruby, the file not containing the expected structure or methods, or the method returning something other than a Hash.

- `OctocatalogDiff::Errors::ConfigurationFileNotFoundError`

  Raised if the configuration file could not be found, *and* `:test => true` was supplied. (Note, if no configuration file is found, but `:test => false`, no error is raised, and `{}` is returned.)
