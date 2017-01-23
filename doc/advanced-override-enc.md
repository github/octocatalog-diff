# Overriding ENC parameters

One powerful feature of `octocatalog-diff` allows you to override ENC parameters when compiling the catalogs, to predict the effect of an ENC parameter change on the catalog. This is useful to simulate a change in agent node configuration without actually setting up an agent to do so.

## Usage

To override an ENC parameter in both catalogs:

```
--enc-override parameters::some_class::some_param=value
```

To override an ENC parameter in the "to" catalog:

```
--to-enc-override parameters::some_class::some_param=value
```

To override an ENC parameter in the "from" catalog:

```
--from-enc-override parameters::some_class::some_param=value
```

You may use as many of these arguments as you wish to adjust as many ENC parameters as you wish.

## Limitations

As presently implemented, this only works on ENCs that supply their results as YAML.

Is your ENC doing something different? Please [let us know](https://github.com/github/octocatalog-diff/issues/new) so we can enhance octocatalog-diff to handle it!

## Examples

Simulate a change to a top-level parameter named "role" only in the "to" catalog:

```
octocatalog-diff -n some-node.example.com -f master -t master \
  --to-enc-override parameters::role=some_new_role
```

Simulate a change in a class parameter between the catalogs:

```
octocatalog-diff -n some-node.example.com -f master -t master \
  --from-enc-override parameters::my_class::my_value=value_in_old \
  --to-enc-override parameters::my_class::my_value=value_in_new
```

Note that each of the examples specified the from branch and to branch to be `master`. There is no requirement that you do this, but you can generally obtain the most accurate test results by changing only one variable at a time.

## Advanced usage

The format for declaring overrides with data types is the same as [overriding facts](/doc/advanced-override-facts.md#advanced-usage).
