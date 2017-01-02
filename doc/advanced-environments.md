# Environment setup

When building a catalog, the default behavior of `octocatalog-diff` is to:

1. Create a temporary directory
2. Create a symlink from `<temporary directory>/environments/production` to the checkout of your code
3. Run Puppet using `environment=production`

If you are using environment names to control the behavior of Puppet, this default behavior may not be suitable. In that case you can invoke the alternate behavior: preserving environments.

## Command line options

### Preserving the environments

When you supply the command line argument `--preserve-environments` (or set `settings[:preserve_environments] = true` in your [configuration file](/doc/configuration.md)), `octocatalog-diff` will instead do the following:

1. Create a temporary directory
2. Create the following symlinks from `<temporary directory>` to the corresponding directories in the checkout of your code:

  - `environments`
  - `manifests`
  - `modules`

3. Run Puppet using an environment you specify via the command line

Note that you must have set `--preserve-environments` in order for the `--environment` and/or `--create-symlinks` options (described below) to have any effect.

### Changing the environment

If you wish to use an environment name other than `production` you can use the `--environment <environment_name>` command line option. This will set the environment for both the `to` and `from` compiles.

```
octocatalog-diff ... --preserve-environments --environment some-env-name
```

If you need to specify different environments for the `to` and `from` compiles, you can use `--to-environment <environment_name>` and `--from-environment <environment_name>`.

```
octocatalog-diff ... --preserve-environments --to-environment first-environment --from-environment second-environment
```

### Controlling symlinks that are created

Within the temporary directory, the `environments` symlink will always be created.

By default, `manifests` and `modules` will also be created from the temporary directory to the corresponding directories in your Puppet code base. If you need to customize the symlinks that are created, you can use the `--create-symlinks <dir1>,<dir2>,...` to list the symlinks that you need.

For example, if you have some code stored in a directory called `modules` and more code stored in a directory called `site`, you could do the following to create the symlinks as desired:

```
octocatalog-diff ... --preserve-environments --create-symlinks manifests,modules,site
```

## Examples

Consider that your Puppet code base is organized as follows:

```
- /opt/puppet
  - environments
    - old
      - environment.conf
      - manifests
        - site.pp
      - modules
        - module_zero
    - new
      - environment.conf
      - manifests
        - site.pp
      - modules
        - module_zero
  - modules
    - module_one
    - module_two
  - site
    - module_three
    - module_four
```

To calculate the difference between the "old" and "new" environment, you could use:

```
octocatalog-diff \
  --bootstrapped-from-dir /opt/puppet \
  --bootstrapped-to-dir /opt/puppet \
  --preserve-environments \
  --from-environment old \
  --to-environment new \
  --create-symlinks modules,site
```

(Note that `--bootstrapped-from-dir` and `--bootstrapped-to-dir` are used to specify the directory path to your code, and `-t` and `-f` are not used. That's because the difference in the catalog is derived from the environment used, and not the branch from a git repository.)
