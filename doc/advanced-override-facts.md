# Overriding facts

One powerful feature of `octocatalog-diff` allows you to override facts when compiling the catalogs, to predict the effect of a fact change on the catalog. This is useful to simulate a change in agent node configuration without actually setting up an agent to do so.

## Usage

To override a fact in the "to" catalog:

```
--to-fact-override factname=value
```

To override a fact in the "from" catalog:

```
--from-fact-override factname=value
```

You may use as many of these arguments as you wish to adjust as many facts as you wish.

## Examples

Simulate a change to its IP address in the "to" branch:

```
octocatalog-diff -n some-node.example.com -f master -t master \
  --to-fact-override ipaddress=10.0.0.1
```

Simulate a change in operating system version (in this case, from Ubuntu trusty to xenial):

```
octocatalog-diff -n some-node.example.com -f master -t master \
  --from-fact-override lsbdistcodename=trusty --to-fact-override lsbdistcodename=xenial
```

Simulate changes to multiple facts, in this case the effect of moving a physical machine into EC2:

```
octocatalog-diff -n some-node.example.com -f master -t master \
  --to-fact-override ec2=true --to-fact-override ec2_ami_id=ami-abcdef01 \
  --to-fact-override ec2_hostname=ip-172-16-0-1.internal --to-fact-override ec2_instance_id=i-ba987654 \
  --to-fact-override ec2_instance_type=c4.2xlarge ...... \
  --to-fact-override virtual=xenhvm
```

Note that each of the examples specified the from branch and to branch to be `master`. There is no requirement that you do this, but you can generally obtain the most accurate test results by changing only one variable at a time.

## Advanced usage

The `octocatalog-diff` parser will attempt to guess the data type based on the input. However, you can force the data type using the following syntax:

```
octocatalog-diff -n some-node.example.com -f master -t master \
  --to-fact-override some_fact='(string)42' fact_to_delete='(nil)'
```

The following data types in parentheses are supported:

| Data type in parentheses | Description |
| ------------------------ | ------------|
| `(string)` | Treat the input as a string |
| `(fixnum)` | Treat the input as an integer (calls the `.to_i` method in ruby) |
| `(float)` | Treat the input as an integer (calls the `.to_f` method in ruby) |
| `(json)` | Treat the input as a JSON string (calls `JSON.parse` in ruby) |
| `(boolean)` | Treat the input as a boolean -- it must be `true` or `false`, case-insensitive |
| `(nil)` | Ignore any characters after `(nil)` and deletes the fact if the fact exists |
