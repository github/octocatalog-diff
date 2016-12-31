# Installation

Before you get started, please make sure that you have the following:

- Ruby 2.0 or higher
- Mac OS, Linux, or other Unix-line operating system (Windows is not supported)
- Ability to install gems, e.g. with [rbenv](https://github.com/rbenv/rbenv) or [rvm](https://rvm.io/), or root privileges to install into the system Ruby
- Puppet agent for [Linux](https://docs.puppet.com/puppet/latest/reference/install_linux.html) or [Mac OS X](https://docs.puppet.com/puppet/latest/reference/install_osx.html), or installed as a gem - required if you are going to compile Puppet catalogs locally without querying a master

## Installing from rubygems.org

`octocatalog-diff` is published on [rubygems](https://rubygems.org/gems/octocatalog-diff).

On a standard system with internet access, installation may be as simple as typing:

```
gem install octocatalog-diff
```

Once the gem is installed, please proceed to [Configuration](/doc/configuration.md).

For general information on installing gems, see: [RubyGems Basics](http://guides.rubygems.org/rubygems-basics/#installing-gems).

## Installing from source

To install from source, you'll need a git client and internet access.

0. Clone the repository

  ```
  git clone https://github.com/github/octocatalog-diff.git
  ```

0. Bootstrap the repository (this will install dependent gems in the project)

  ```
  cd octocatalog-diff
  ./script/bootstrap
  ```

0. RECOMMENDED: Make sure the tests pass on your machine

  ```
  rake
  ```

  Note: If tests fail on your machine with a clean checkout of the master branch, we would definitely appreciate if you would report it. Please [open an issue](https://github.com/github/octocatalog-diff/issues/new) with the output and some information about your system (e.g. OS, ruby version, etc.) to let us know.

Once the code is downloaded and bootstrapped, please proceed to [Configuration](/doc/configuration.md).

## Running from an alternate branch

We have prepared specific instructions for running `octocatalog-diff` from a non-master branch, for testing changes that may be requested by the developers.

- [Running octocatalog-diff from a branch](/doc/dev/run-from-branch.md)
