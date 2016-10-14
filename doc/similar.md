# Similar Projects

We are aware of the following projects that do similar things to octocatalog-diff:

- [Puppet's catalog_preview Puppet module](https://forge.puppet.com/puppetlabs/catalog_preview)

  Installs as a module into your Puppet codebase and helps with migration from older Puppet versions to newer ones, or from open source Puppet to Puppet Enterprise. Also provides the ability to compare environments (branches). Requires a full working Puppet installation.

- [Zack Smith's catalog_diff Puppet module](https://forge.puppet.com/zack/catalog_diff)

  Installs as a module into your Puppet codebase, allowing you to diff catalogs created by different versions of Puppet. Requires a full working Puppet installation.

- [camptocamp's puppet-catalog-diff-viewer](https://github.com/camptocamp/puppet-catalog-diff-viewer)

  A viewer for JSON reports produced by the catalog_diff Puppet module.

`octocatalog-diff` differs from the above projects by running on a system without a fully configured Puppet installation (such as a developer workstation or CI server). This approach allows developers to run it without having access to the production Puppet servers, and it does not put any load on production Puppet masters when it compiles and compares catalogs.
