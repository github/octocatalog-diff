# Environment variables

The following environment variables have special meaning to octocatalog-diff:

### `OCTOCATALOG_DIFF_CONFIG_FILE`

### `OCTOCATALOG_DIFF_CUSTOM_VERSION`

When set, the `octocatalog-diff` CLI will display this as the version number within debugging, instead of the version number in the package. This is most useful if you want to use or include a git SHA in the version number.

```
$ export OCTOCATALOG_DIFF_CUSTOM_VERSION="@$(git rev-parse HEAD)"
$ octocatalog-diff -d ...
D, [2017-10-12T08:57:46.454738 #35205] DEBUG -- : Running octocatalog-diff @504d7f3c91267e5193beb103caae5d4d8cebfee3 with ruby 2.3.1
...
```

### `OCTOCATALOG_DIFF_DEVELOPER_PATH`

When set, instead of loading libraries from the system or bundler location, libraries will be loaded from the specified value of this environment variable. This is used internally for development as we point users to unreleased code for debugging or testing.

```
$ export OCTOCATALOG_DIFF_DEVELOPER_PATH=$HOME/git-checkouts/octocatalog-diff
$ octocatalog-diff ...
```

### `OCTOCATALOG_DIFF_TEMPDIR`

When set:

- `octocatalog-diff` will create all of its temporary directories within the specified directory.
- `octocatalog-diff` will not attempt to remove any temporary directories it creates.

This is useful in the following situations:

- You are calling `octocatalog-diff` from within another program which is highly parallelized, and `at_exit` handlers are difficult to implement. Instead of figuring that all out (if it can even be figured out), you create a temporary directory before the parallelized logic, and remove it afterwards.

- You wish to debug intermediate output. For example, you may be instructed to set this variable and send some of the output to the project maintainers if you request assistance.

This variable is used internally for the parallelized logic for catalog compilation, but the value set from the environment will override any internal usage.

### `OCTOCATALOG_DIFF_VERSION`

### `PUPPETDB_HOST`

### `PUPPETDB_PORT`

### `PUPPETDB_URL`

### `PUPPET_FACT_DIR`
