# Output formats

By default, when you run `octocatalog-diff`, it will display the results in color on STDOUT.

An example of the output display is shown on the [main page](/README.md#example).

Log messages will be written to STDERR.

## Writing to a file

If you would like to write the results to a file instead, specify:

      octocatalog-diff -o OUTPUT_FILE_PATH [other options]

When you output to a file, the default output format is the same as the on-screen format, but without the color.

If you would like to redirect the debug/log output to a file, you can use shell redirection:

      octocatalog-diff [options] 2>/var/log/octocatalog-diff.log

## Alternate output formats

You can specify the `--output-format FORMAT` command line options with one of the following values for FORMAT:

| FORMAT | Explanation |
| ------ | ----------- |
| text   | (Default) Traditional human readable output |
| json   | JSON output of the difference array |

## Color

As previously noted, color text is enabled for on-screen display and disabled for file output.

You can override the automatic selection via:

- `--color` to turn colored text on
- `--no-color` to turn colored text off

Note: There is no color used for JSON output, regardless of whether the display is on-screen or redirected to a file, and regardless of whether you specify the `--color` command line option.

## JSON format

### Top level format

The JSON result is in the following format:

```
{
  "diff": [
    DIFFERENCE_ARRAY_1,
    DIFFERENCE_ARRAY_2,
    ...
  ],
  "header": "HEADER STRING"
}
```

### Format of difference arrays

Each difference array is in one of the following formats:

#### Addition or removal

```
[
  (String) Change Type (+ or -),
  (String) Type, Title separated by \f,
  (Hash) Object as it exists in old or new catalog,
  (Hash) { file: "MANIFEST FILENAME", line: LINE_NUMBER }
]
```

When the change type is '+' this indicates that the resource was added (i.e., it exists in the new catalog and not the old). '-' indicates that the resource was removed (i.e., it exists in the old catalog, but not the new). It is important to note that a removed resource does not necessarily cause cleanup on the target system.

#### Change

```
[
  (String) Change Type (~ or !),
  (String) Type, Title, Attribute separated by \f,
  (?) Object as it exists in old catalog,
  (?) Object as it exists in new catalog,
  (Hash) { file: "MANIFEST FILENAME", line: LINE_NUMBER } from old catalog,
  (Hash) { file: "MANIFEST FILENAME", line: LINE_NUMBER } from new catalog
]
```

Note that `~` and `!` are used internally to signify different types of changes, but for display purposes they should be considered equivalent.

The objects as they appear in the old and new catalogs can be many different data types. Strings, integers, and booleans are the most common. `null` represents that the attribute was not present in the catalog or that it was set to Puppet's `undef`. (`null` in JSON is equivalent to Ruby's `nil`.)

### Notes

- In the second array field, the type, title, and attribute are separated by the form feed (`\f`) character. This was chosen because it is unlikely to be encountered in actual naming. You are guaranteed that when splitting on `\f`, the first item is the type, the second item is the title, and the third (and subsequent) items represent the attribute, with each key in the data structure also separated by `\f`.

- If the manifest name and line number are not reported in the catalog, the hashes may have `nil` values for the file and line keys.
