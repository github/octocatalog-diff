# Enabling the cache directory

If you are running `octocatalog-diff` on your workstation, enabling the cache directory can support faster runs by:

- Bootstrapping the `master` branch and saving that in a directory, so that you do not need to bootstrap the `master` branch each time you run `octocatalog-diff`.
- Saving the `master` catalog for each node, so that for the second and subsequent difference calculation, this catalog does not need to be re-computed.

We recommend that you configure these settings in your [configuration file](/doc/configuration.md), although it is possible to specify these settings on the command line as well.

## Cache directory options

There are two options that pertain to the cache directory:

- `--cached-master-dir DIRECTORY_PATH`

  This is the full path to the directory where the bootstrapped master directory will reside. Please note that this directory will be created if it doesn't exist, but for the directory to be created, *its parent directory must already exist*. You will receive an error message if you specify a directory path that is not a directory, or cannot be created as a directory.

  Note that a subdirectory called `.catalogs` will be created within the chosen directory paths, and compiled `master` catalogs for nodes will be stored therein.

- `--safe-to-delete-cached-master-dir DIRECTORY_PATH`

  If you want to allow `octocatalog-diff` to delete the cached master directory when it becomes stale, set this option. If you do not set this option, and the cached master directory becomes stale, an error will be raised.

  Historically, this was separated from `--cached-master-dir` to provide a separation between routine behavior (creating files and catalogs) and destructive behavior (deleting an entire directory).
