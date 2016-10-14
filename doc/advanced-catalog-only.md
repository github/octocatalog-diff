# Building catalogs instead of diffing catalogs

`octocatalog-diff` is designed primarily to build two catalogs and compare them. However, it can also simply generate the catalog without performing comparisons.

## Usage

The `--catalog-only` command line flag triggers the following behavior:

  - The compiled catalog (not the difference) is written to the screen or stored in a file
  - Only the "to" branch is relevant (the "from" branch is not touched)
  - Options that control [output formats](/doc/advanced-output-formats.md), such as color and JSON format, do not apply
  - The `-o FILENAME` option will write the catalog to the indicated file rather than displaying it on screen

## Examples

Building a catalog for a node from the current working directory and displaying on screen:

```
octocatalog-diff -n some-node.example.com --catalog-only
```

Building a catalog for a node from a specific branch and saving to a file:

```
octocatalog-diff -n some-node.example.com -t my-branch -o /tmp/some-node.json --catalog-only
```

As part of a CI job, testing whether a catalog for a particular host compiles:

```
octocatalog-diff -n some-node.example.com -o /dev/null --catalog-only
if [ $? -eq 0 ]; then
  echo "Pass"
else
  echo "Fail"
fi
```
