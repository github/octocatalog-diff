# Output hacks

This document describes command line options that are useful to format the output of the human readable text format (which is the default). Note that if you are [outputting in JSON](/doc/advanced-output-formats.md#json-format), none of these options will have any effect.

See also [Output formats](/doc/advanced-output-formats.md) for details on text vs. JSON and color vs. non-color.

## Displaying the detail of added resources (`--display-detail-add`)

By default, `octocatalog-diff` will display an added resource on one line, without displaying all of the parameters. For example:

```
+ File[/tmp/my-file]
```

If you would like to see the detail (all parameters and other settings), provide the `--display-detail-add` command line argument. Then the display will look more like:

```
+ File[/tmp/my-file] =>
   parameters =>
     "content": "This is my amazing new file",
     "ensure": "file",
     "group": "root",
     "mode": "0755",
     "owner": "root"
```

If any line is too long, it will be abbreviated with `...`.

## Displaying the file and line giving rise to a resource (`--display-source`)

To get help tracking down the file and line giving rise to a resource, provide the `--display-source` command line argument.

If the file name and line number are known in the catalog, they will be displayed with the resource.

If this information is the same between the old and new catalogs, it will be displayed just once. If the information differs, it will be displayed twice in a `diff` format: the `-` represents the location in the old catalog, and `+` represents the location in the new catalog.

## Tuning the level of debugging (`--debug`, `--quiet`)

`octocatalog-diff` comes with 3 levels of log output. From least to most:

| Command line option | Description |
| ------------------- | ----------- |
| `--quiet` (or `-q`) | Only critical errors are displayed to STDERR |
| (default)           | Critical errors and informational messages (statistics mainly) are displayed to STDERR |
| `--debug` (or `-d`) | Full debugging messages are displayed to STDERR |
