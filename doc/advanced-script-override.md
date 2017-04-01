# Overriding external scripts

## Background

During normal operation, `octocatalog-diff` runs certain scripts or commands from the underlying operating system. For example, it may run `git` to check out a certain code branch, and run `puppet` to build a catalog.

Each external script is found within the [`scripts`](/scripts) directory.

## How to override scripts

### Command line option

It is possible to override these scripts with customized versions. To do this, specify a directory that contains replacement scripts via the command line:

```
octocatalog-diff [other options] --override-script-path /path/to/scripts ...
```

### Configuration file

You can also specify this option via a [configuration file](/doc/configuration.md) setting:

```
settings[:override_script_path] = '/path/to/scripts'
```

### Writing replacement scripts

Within the override script path you've configured, place a file with the same name as the built-in script. For example, if you wish to override the `git-extract.sh` script with a custom version, also name your script `git-extract.sh`. (Do NOT create subdirectories within the override directory.)

If you specify an override script path but a particular script is not present there, octocatalog-diff will default to the built-in script. This means that you do not need to create unmodified copies of the built-in scripts. Only override the scripts you need to change.

### Notes

Please note that these scripts are considered part of octocatalog-diff, and not part of your Puppet codebase. Therefore, the path to your scripts must be an absolute path, and we do not support (or intend to support) using multiple script directories during the same run of octocatalog-diff.

## Explanation of scripts

This is an explanation of the [existing scripts supplied by octocatalog-diff](/scripts):

- [`env.sh`](/scripts/env)

    Prints out the environment. This is currently only used for spec tests.

- [`git-extract.sh`](/scripts/git-extract)

    Extracts a specified branch from the git repository into a specified target directory.

- [`puppet.sh`](/scripts/puppet)

    Runs puppet (with additional command line arguments), generally used to compile a catalog or determine the Puppet version.
