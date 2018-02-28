# Requirements

To run `octocatalog-diff` you will need these basics:

- An appropriate Puppet version and [corresponding ruby version](https://puppet.com/docs/puppet/5.4/system_requirements.html)
  - Puppet 5.x officially supports Ruby 2.4
  - Puppet 4.x officially supports Ruby 2.1, but seems to work fine with later versions as well
  - Puppet 3.8.7 -- we attempt to maintain compatibility in `octocatalog-diff` to facilitate upgrades even though this version is no longer supported by Puppet
  - We don't officially support Puppet 3.8.6 or before
- Mac OS, Linux, or other Unix-line operating system (Windows is not supported)
- Ability to install gems, e.g. with [rbenv](https://github.com/rbenv/rbenv) or [rvm](https://rvm.io/), or root privileges to install into the system Ruby
- Puppet agent for [Linux](https://docs.puppet.com/puppet/latest/reference/install_linux.html) or [Mac OS X](https://docs.puppet.com/puppet/latest/reference/install_osx.html), or installed as a gem

We recommend that you also have the following to get the most out of `octocatalog-diff`, but these are not absolute requirements:

- If your Puppet code stored in a git repository, `octocatalog-diff` can check out branches for you as it does its comparisons. Your git repository can be stored on [GitHub.com](https://github.com/), [GitHub Enterprise](https://enterprise.github.com/home), or similar. If your Puppet code is not stored in a git repository, you can still point the tool at "from" and "to" directories, but you'll have to check them out yourself.

- If you have API access (HTTPS) to PuppetDB, `octocatalog-diff` can retrieve facts automatically and also support [exported resources](https://docs.puppet.com/puppet/latest/reference/lang_exported.html) if you use them. If you are not using PuppetDB or don't have access, the tool can still read facts from YAML files.

- If your site uses an [external node classifier](https://docs.puppet.com/guides/external_nodes.html), `octocatalog-diff` can execute the ENC script as part of its catalog compiles. Depending on how your ENC is designed, this may require network access or credentials to some service. If you are not using an ENC, that's fine. If you have an ENC but don't have the requisite access, depending on your setup the tool could produce unexpected results.
