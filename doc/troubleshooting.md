# Troubleshooting

Things not quite working as expected? This section will contain hints to help you get up and running.

### Make sure the tests pass

If you are getting errors from ruby, we'd really like to know if the tests are passing on your platform. Please follow the [installation instructions](/doc/installation.md#installing-from-source) to install octocatalog-diff from source, if you have not already done so. Once the repository is checked out, change into the directory run `rake` to perform the tests.

If you get test failures from a clean checkout of the master branch, please [open an issue](https://github.com/github/octocatalog-diff/issues/new) to let us know.

### Make sure your configuration file is found and error-free

Run the following command to test for the existence and integrity of your configuration file.

```
octocatalog-diff --config-test
```

If you get an error indicating that the file can't be found, or you get errors arising from the content of the file, please review the [configuration instructions](/doc/configuration.md) to make sure you've set things up correctly.

### Run the command in debug mode

Supplying `-d` on the command line, in addition to the node name and any other arguments, will provide a substantial amount of debugging information to the terminal window. If you ultimately end up requesting our help, we will need this debugging output.

Example:

```
octocatalog-diff -d -n SomeNodeName.yourdomain.com
```

### Run only certain components of the command

To perform the bootstrapping and catalog compilation in separate steps, you can run octocatalog-diff with arguments asking it to do only one or the other. This will help you narrow down whether the problem is in the bootstrapping (first command) or catalog compilation (second command).

Be sure you are in the directory where your Puppet code is checked out when you run these commands.

To run just the bootstrapping code (do this within a checkout of your Puppet repository):

```
mkdir /tmp/octo-test
octocatalog-diff -d --bootstrap-then-exit --bootstrapped-from-dir=/tmp/octo-test
```

To run just the catalog compilation code (do this within a checkout of your Puppet repository):

```
octocatalog-diff -d -n SomeNodeName.yourdomain.com -o /tmp/catalog.json --bootstrapped-to-dir=$PWD --catalog-only
```

### Contact us

Still having trouble? Please [open an issue](https://github.com/github/octocatalog-diff/issues/new) and we will do our best to help.

Please follow the provided issue template, which will ask you for certain output that we need to diagnose the problem.
