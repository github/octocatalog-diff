# Requirements

To run `octocatalog-diff` you will need these basics:

- Ruby 2.0 through 2.4 (we test octocatalog-diff with Ruby 2.0, 2.1, 2.2, 2.3, and 2.4)
- Mac OS, Linux, or other Unix-line operating system (Windows is not supported)
- Ability to install gems, e.g. with [rbenv](https://github.com/rbenv/rbenv) or [rvm](https://rvm.io/), or root privileges to install into the system Ruby
- Puppet agent for [Linux](https://docs.puppet.com/puppet/latest/reference/install_linux.html) or [Mac OS X](https://docs.puppet.com/puppet/latest/reference/install_osx.html), or installed as a gem (we support Puppet 3.8.7 and all versions of Puppet 4.x)

We recommend that you also have the following to get the most out of `octocatalog-diff`, but these are not absolute requirements:

- If your Puppet code stored in a git repository, `octocatalog-diff` can check out branches for you as it does its comparisons. Your git repository can be stored on [GitHub.com](https://github.com/), [GitHub Enterprise](https://enterprise.github.com/home), or similar. If your Puppet code is not stored in a git repository, you can still point the tool at "from" and "to" directories, but you'll have to check them out yourself.

- If you have API access (HTTPS) to PuppetDB, `octocatalog-diff` can retrieve facts automatically and also support [exported resources](https://docs.puppet.com/puppet/latest/reference/lang_exported.html) if you use them. If you are not using PuppetDB or don't have access, the tool can still read facts from YAML files.

- If your site uses an [external node classifier](https://docs.puppet.com/guides/external_nodes.html), `octocatalog-diff` can execute the ENC script as part of its catalog compiles. Depending on how your ENC is designed, this may require network access or credentials to some service. If you are not using an ENC, that's fine. If you have an ENC but don't have the requisite access, depending on your setup the tool could produce unexpected results.
