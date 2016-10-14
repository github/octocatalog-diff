# Basic usage

The most basic usage of octocatalog-diff is to compare catalogs built from two different git branches, for a node of your choosing.

You should be aware of these defaults, all of which are [configurable](/doc/configuration.md).

- octocatalog-diff will default to compiling catalogs based on the assumption that your Puppet code resides in a git repository. If your Puppet code does not reside in a git repository, head over to the [advanced instructions](/doc/advanced.md) for workarounds.

- octocatalog-diff will compile the catalog produced from the `origin/master` branch of your repository as the "from" catalog, and the catalog produced from your current working directory as the "to" catalog. You can override these defaults with the `-f BRANCH` and `-t BRANCH` arguments, for the "from" and "to" branches, respectively.

- octocatalog-diff will assume you are not using hiera or an external node classifier, unless you [configure](/doc/configuration.md) it accordingly, or use the appropriate command line arguments to point it at your hiera configuration and/or ENC script.

You are required to provide the following information, either as a command line argument, in the [configuration](/doc/configuration.md), or in some cases, via the environment:

- The node name whose catalogs you wish to compile. Use `-n HOSTNAME` on the command line.

- Facts, which can either be retrieved from [PuppetDB](/doc/configuration-puppetdb.md) or via the `--fact-file` command line option. See the usage examples below.

## Examples

### From git repository with facts from PuppetDB

```
export PUPPETDB_URL="http://puppetdb.yourdomain.com:8080"
cd Puppet_Checkout_Directory
git checkout master
git pull
octocatalog-diff -n SomeNodeName.yourdomain.com
```

### Using a fact file

You can retrieve the fact file from your Puppet Master (3.x) typically in `/var/lib/puppet/yaml/facts/<node>.yaml`, or your Puppet Server (4.x) typically in `/opt/puppetlabs/server/data/puppetserver/yaml/facts/<node>.yaml`. We recommend using PuppetDB as a more convenient fact source, but you can copy the fact file for a node from your Puppet server onto the machine running octocatalog-diff for testing purposes.

```
# Copy the fact file for SomeNodeName.yourdomain.com into /tmp/SomeNodeName.yourdomain.com.yaml
cd Puppet_Checkout_Directory
git checkout master
git pull
octocatalog-diff -n SomeNodeName.yourdomain.com --fact-file /tmp/SomeNodeName.yourdomain.com.yaml
```

## Using hiera

This example demonstrates how to point octocatalog-diff at your Hiera configuration file. The Hiera configuration file for your site might be found in `/etc/puppet/hiera.yaml` (for Puppet 3.x) or `/etc/puppetlabs/puppet/hiera.yaml` (for Puppet 4.x).

Note that you will either need to configure the PuppetDB URL or specify a `--fact-file` for this to work.

```
# Copy the fact file for SomeNodeName.yourdomain.com into /tmp/SomeNodeName.yourdomain.com.yaml
# (or)
# Set the PUPPETDB_URL variable as shown in the first example
#
# Also copy hiera.yaml from your Puppet master into the /tmp directory

cd Puppet_Checkout_Directory
git checkout master
git pull
octocatalog-diff -n SomeNodeName.yourdomain.com --hiera-config /tmp/hiera.yaml
```

Depending on your hiera configuration, you may also need to supply the `--hiera-path-strip` option (or set that option in your [configuration](/doc/configuration.md)). Consult the [configuring octocatalog-diff to use Hiera](/doc/configuration-hiera.md) document for details on this option.

## Next steps

If you're ready to learn about additional command line flags to customize your experience, head to [Advanced usage](/doc/advanced.md).

If you experience problems running octocatalog-diff even with these most basic arguments, please see [Troubleshooting](/doc/troubleshooting.md).

If you are not using git to manage your Puppet source code, you will need to see the [Advanced usage](/doc/advanced.md) instructions to get your directories manually bootstrapped for use, or use one of the other supported methods to build catalogs.
