# Limitations

Testing of Puppet catalogs is faster than running the agent, but you need to be careful of the following limitations:

0. Facts are not taken from a live agent run

  octocatalog-diff by default uses the facts reported from a node's more recent Puppet run. If you have made changes to custom facts, catalog testing will **NOT** be an adequate test of whether your custom facts worked. (You can still use octocatalog-diff to help predict changes to nodes based on changes to facts, by overriding facts on the command line.)

0. Agents handle depenency ordering and implementation details

  The catalog defines the state of the system, but it's up to the agent to determine how to bring the system to a point that matches the catalog. The agent is responsible for order of operations and actually making the change.

  Two specific situations that catalog testing does **NOT** detect are:

  - Dependency loops (e.g., you have made A require B, B require C, and C require A).

  - Operations not supported by the provider. For example, assume that in your current Puppet manifests, you set the size of a file system to 100 GB. You change this in your new branch to 50 GB. octocatalog-diff will dutifully report this change to you. However, the agent will fail to make the change, because it is not possible to shrink a file system from 100 GB to 50 GB.

0. Changes in underlying providers may not be noticed

  Consider that you are using a Puppet module that creates a file system. The current implementation of that module checks to see if *any* file system is present on the device, and creates a new file system there if no file system was present. You upgrade the module, and the new version checks to see if *the specified* file system is present on the device, and reformats the device with the specified file system (regardless of whether there was no file system or if there was an existing file system of a different type). There would be no catalog changes (hence octocatalog-diff would report nothing) because the catalog simply instructs the agent to create a file system of the specified type at the defined location. However, the actual implementation of those instructions has changed dramatically.

In general catalog testing is great for:

  - Refactoring classes and defined types (which do not have custom providers)
  - Moving information around in hiera
  - Generally adding, removing, or modifying standard Puppet resources
  - Checking the net effect of any custom functions (`lib/puppet/parser/functions`) since these execute during catalog compilation

Catalog testing in general (including octocatalog-diff and similar tools) is generally inadequate for:

  - Changes to custom facts
  - Changes to any providers (includes upgrading any Puppet modules from Puppet Forge or other sources)
  - Changes to order of operations (before, require, subscribe, notify)
