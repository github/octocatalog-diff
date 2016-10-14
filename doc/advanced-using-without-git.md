# Using `octocatalog-diff` without git

`octocatalog-diff` is designed to be used with git, and is developed by GitHub. This means that on a daily basis, it is run thousands of times on repositories backed by GitHub for CI jobs reported to GitHub.

If you do not manage your Puppet code with git, it is still possible to use `octocatalog-diff`, but you will not be able to take advantage of the git integrations and will need to do some things manually.

## Usage

You will need to use these command line options (at minimum):

  - `--bootstrapped-from-dir`: The directory containing your checked out "from" Puppet code, and if there is any [bootstrapping](/doc/advanced-bootstrap.md) it must already be done.

  - `--bootstrapped-to-dir`: The directory containing your checked out "to" Puppet code, and if there is any [bootstrapping](/doc/advanced-bootstrap.md) it must already be done.

You are responsible for the process by which you check out code from your version control system into two separate directories and run any necessary bootstrapping. You will need to script that step *before* invoking `octocatalog-diff`.
