<!--
  This document is automatically generated via the `rake doc:build` task.
  Please DO NOT edit this document manually, as your changes will be lost.
  Formatting changes should be made to the template: /rake/templates/optionsref.erb
-->
# Command line options reference

## Usage

```
Usage: octocatalog-diff [command line options]
    -n, --hostname HOSTNAME          Use PuppetDB facts from last run of hostname
        --basedir DIRNAME            Use an alternate base directory (git checkout of puppet repository)
    -f, --from FROM_BRANCH           Branch you are coming from
    -t, --to TO_BRANCH               Branch you are going to
        --from-catalog FILENAME      Use a pre-compiled catalog 'from'
        --to-catalog FILENAME        Use a pre-compiled catalog 'to'
        --bootstrap-script FILENAME  Bootstrap script relative to checkout directory
        --bootstrap-current          Run bootstrap script for the current directory too
        --debug-bootstrap            Print debugging output for bootstrap script
        --bootstrap-environment "key1=val1,key2=val2,..."
                                     Bootstrap script environment variables in key=value format
        --bootstrapped-from-dir DIRNAME
                                     Use a pre-bootstrapped 'from' directory
        --bootstrapped-to-dir DIRNAME
                                     Use a pre-bootstrapped 'to' directory
        --bootstrap-then-exit        Bootstrap from-dir and/or to-dir and then exit
        --[no-]color                 Enable/disable colors in output
    -o, --output-file FILENAME       Output results into FILENAME
        --output-format FORMAT       Output format: text,json,legacy_json
    -d, --[no-]debug                 Print debugging messages to STDERR
    -q, --[no-]quiet                 Quiet (no status messages except errors)
        --ignore "Type1[Title1],Type2[Title2],..."
                                     More resources to ignore in format type[title]
        --[no-]include-tags          Include changes to tags in the diff output
        --fact-file FILENAME         Fact file to use instead of node lookup
        --cached-master-dir PATH     Cache bootstrapped origin/master at this path
        --master-cache-branch BRANCH Branch to cache
        --safe-to-delete-cached-master-dir PATH
                                     OK to delete cached master directory at this path
        --hiera-config PATH          Relative path to hiera YAML file
        --no-hiera-config            Disable hiera config file installation
        --hiera-path PATH            Path to hiera data directory, relative to top directory of repository
        --no-hiera-path              Do not use any default hiera path settings
        --hiera-path-strip PATH      Path prefix to strip when munging hiera.yaml
        --no-hiera-path-strip        Do not use any default hiera path strip settings
        --ignore-attr "attr1,attr2,..."
                                     Attributes to ignore
        --filters FILTER1[,FILTER2[,...]]
                                     Filters to apply
        --[no-]display-source        Show source file and line for each difference
        --[no-]validate-references "before,require,subscribe,notify"
                                     References to validate
        --[no-]compare-file-text     Compare text, not source location, of file resources
        --[no-]storeconfigs          Enable integration with puppetdb for collected resources
        --retry-failed-catalog N     Retry building a failed catalog N times
        --no-enc                     Disable ENC
        --enc PATH                   Path to ENC script, relative to checkout directory or absolute
        --from-enc PATH              Path to ENC script (for the from catalog only)
        --to-enc PATH                Path to ENC script (for the to catalog only)
        --[no-]display-detail-add    Display parameters and other details for added resources
        --no-header                  Do not print a header
        --default-header             Print default header with output
        --header STRING              Specify header for output
        --parser PARSER_NAME         Specify parser (default, future)
        --parser-from PARSER_NAME    Specify parser (default, future)
        --parser-to PARSER_NAME      Specify parser (default, future)
        --[no-]display-datatype-changes
                                     Display changes in data type even when strings match
        --[no-]catalog-only          Only compile the catalog for the "to" branch but do not diff
        --[no-]from-puppetdb         Pull "from" catalog from PuppetDB instead of compiling
        --[no-]parallel              Enable or disable parallel processing
        --puppet-binary STRING       Full path to puppet binary globally
        --to-puppet-binary STRING    Full path to puppet binary for the to branch
        --from-puppet-binary STRING  Full path to puppet binary for the from branch
        --facts-terminus STRING      Facts terminus: one of yaml, facter
        --puppetdb-ssl-ca FILENAME   CA certificate that signed the PuppetDB certificate
        --puppetdb-ssl-client-password PASSWORD
                                     Password for SSL client key to connect to PuppetDB
        --puppetdb-ssl-client-cert FILENAME
                                     SSL client certificate to connect to PuppetDB
        --puppetdb-ssl-client-key FILENAME
                                     SSL client key to connect to PuppetDB
        --puppetdb-ssl-client-password-file FILENAME
                                     Read password for SSL client key from a file
        --puppetdb-url URL           PuppetDB base URL
        --puppetdb-api-version N     Version of PuppetDB API (3 or 4)
        --fact-override STRING1[,STRING2[,...]]
                                     Override fact globally
        --to-fact-override STRING1[,STRING2[,...]]
                                     Override fact for the to branch
        --from-fact-override STRING1[,STRING2[,...]]
                                     Override fact for the from branch
        --puppet-master STRING       Hostname or Hostname:PortNumber for Puppet Master globally
        --to-puppet-master STRING    Hostname or Hostname:PortNumber for Puppet Master for the to branch
        --from-puppet-master STRING  Hostname or Hostname:PortNumber for Puppet Master for the from branch
        --puppet-master-api-version STRING
                                     Puppet Master API version (2 for Puppet 3.x, 3 for Puppet 4.x) globally
        --to-puppet-master-api-version STRING
                                     Puppet Master API version (2 for Puppet 3.x, 3 for Puppet 4.x) for the to branch
        --from-puppet-master-api-version STRING
                                     Puppet Master API version (2 for Puppet 3.x, 3 for Puppet 4.x) for the from branch
        --puppet-master-ssl-ca STRING
                                     Full path to CA certificate that signed the Puppet Master certificate globally
        --to-puppet-master-ssl-ca STRING
                                     Full path to CA certificate that signed the Puppet Master certificate for the to branch
        --from-puppet-master-ssl-ca STRING
                                     Full path to CA certificate that signed the Puppet Master certificate for the from branch
        --puppet-master-ssl-client-cert STRING
                                     Full path to certificate file for SSL client auth to Puppet Master globally
        --to-puppet-master-ssl-client-cert STRING
                                     Full path to certificate file for SSL client auth to Puppet Master for the to branch
        --from-puppet-master-ssl-client-cert STRING
                                     Full path to certificate file for SSL client auth to Puppet Master for the from branch
        --puppet-master-ssl-client-key STRING
                                     Full path to key file for SSL client auth to Puppet Master globally
        --to-puppet-master-ssl-client-key STRING
                                     Full path to key file for SSL client auth to Puppet Master for the to branch
        --from-puppet-master-ssl-client-key STRING
                                     Full path to key file for SSL client auth to Puppet Master for the from branch
        --enc-override STRING1[,STRING2[,...]]
                                     Override parameter from ENC globally
        --to-enc-override STRING1[,STRING2[,...]]
                                     Override parameter from ENC for the to branch
        --from-enc-override STRING1[,STRING2[,...]]
                                     Override parameter from ENC for the from branch
        --puppet-master-timeout STRING
                                     Puppet Master catalog retrieval timeout in seconds globally
        --to-puppet-master-timeout STRING
                                     Puppet Master catalog retrieval timeout in seconds for the to branch
        --from-puppet-master-timeout STRING
                                     Puppet Master catalog retrieval timeout in seconds for the from branch
        --pe-enc-url URL             Base URL for Puppet Enterprise ENC endpoint
        --pe-enc-token TOKEN         Token to access the Puppet Enterprise ENC API
        --pe-enc-token-file PATH     Path containing token for PE node classifier, relative or absolute
        --pe-enc-ssl-ca FILENAME     CA certificate that signed the ENC API certificate
        --pe-enc-ssl-client-cert FILENAME
                                     SSL client certificate to connect to PE ENC
        --pe-enc-ssl-client-key FILENAME
                                     SSL client key to connect to PE ENC
        --no-ignore-tags             Disable ignoring based on tags
        --ignore-tags STRING1[,STRING2[,...]]
                                     Specify tags to ignore
        --[no-]preserve-environments Enable or disable environment preservation
        --environment STRING         Environment for catalog compilation globally
        --to-environment STRING      Environment for catalog compilation for the to branch
        --from-environment STRING    Environment for catalog compilation for the from branch
        --create-symlinks STRING1[,STRING2[,...]]
                                     Symlinks to create globally
        --to-create-symlinks STRING1[,STRING2[,...]]
                                     Symlinks to create for the to branch
        --from-create-symlinks STRING1[,STRING2[,...]]
                                     Symlinks to create for the from branch
        --command-line STRING1[,STRING2[,...]]
                                     Command line arguments globally
        --to-command-line STRING1[,STRING2[,...]]
                                     Command line arguments for the to branch
        --from-command-line STRING1[,STRING2[,...]]
                                     Command line arguments for the from branch
        --pass-env-vars VAR1[,VAR2[,...]]
                                     Environment variables to pass
        --[no-]suppress-absent-file-details
                                     Suppress certain attributes of absent files

```

## Detailed options description

<table>
  <tr>
    <th>Option</th>
    <th>Description</th>
    <th>Extended Description</th>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--basedir DIRNAME</code></pre>
    </td>
    <td valign=top>
      Use an alternate base directory (git checkout of puppet repository)
    </td>
    <td valign=top>
      Option to set the base checkout directory of puppet repository (<a href="../lib/octocatalog-diff/cli/options/basedir.rb">basedir.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--bootstrap-current </code></pre>
    </td>
    <td valign=top>
      Run bootstrap script for the current directory too
    </td>
    <td valign=top>
      Option to bootstrap the current directory (by default, the bootstrap script is NOT
run when the catalog builds in the current directory). (<a href="../lib/octocatalog-diff/cli/options/bootstrap_current.rb">bootstrap_current.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--bootstrap-environment "key1=val1,key2=val2,..."</code></pre>
    </td>
    <td valign=top>
      Bootstrap script environment variables in key=value format
    </td>
    <td valign=top>
      Allow the bootstrap environment to be set up via the command line. (<a href="../lib/octocatalog-diff/cli/options/bootstrap_environment.rb">bootstrap_environment.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--bootstrap-script FILENAME</code></pre>
    </td>
    <td valign=top>
      Bootstrap script relative to checkout directory
    </td>
    <td valign=top>
      Allow specification of a bootstrap script. This runs after checking out the directory, and before running
puppet there. Good for running librarian to install modules, and anything else site-specific that needs
to be done. (<a href="../lib/octocatalog-diff/cli/options/bootstrap_script.rb">bootstrap_script.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--bootstrap-then-exit </code></pre>
    </td>
    <td valign=top>
      Bootstrap from-dir and/or to-dir and then exit
    </td>
    <td valign=top>
      Option to bootstrap directories and then exit (<a href="../lib/octocatalog-diff/cli/options/bootstrap_then_exit.rb">bootstrap_then_exit.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--bootstrapped-from-dir DIRNAME</code></pre>
    </td>
    <td valign=top>
      Use a pre-bootstrapped 'from' directory
    </td>
    <td valign=top>
      Allow (or create) directories that are already bootstrapped. Handy to allow "bootstrap once, build many"
to save time when diffing multiple catalogs on this system. (<a href="../lib/octocatalog-diff/cli/options/bootstrapped_dirs.rb">bootstrapped_dirs.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--bootstrapped-to-dir DIRNAME</code></pre>
    </td>
    <td valign=top>
      Use a pre-bootstrapped 'to' directory
    </td>
    <td valign=top>
      Allow (or create) directories that are already bootstrapped. Handy to allow "bootstrap once, build many"
to save time when diffing multiple catalogs on this system. (<a href="../lib/octocatalog-diff/cli/options/bootstrapped_dirs.rb">bootstrapped_dirs.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--cached-master-dir PATH</code></pre>
    </td>
    <td valign=top>
      Cache bootstrapped origin/master at this path
    </td>
    <td valign=top>
      Cache a bootstrapped checkout of 'master' and use that for time-saving when the SHA
has not changed. (<a href="../lib/octocatalog-diff/cli/options/cached_master_dir.rb">cached_master_dir.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--catalog-only
--no-catalog-only </code></pre>
    </td>
    <td valign=top>
      Only compile the catalog for the "to" branch but do not diff
    </td>
    <td valign=top>
      When set, --catalog-only will only compile the catalog for the 'to' branch, and skip any
diffing activity. The catalog will be printed to STDOUT or written to the output file. (<a href="../lib/octocatalog-diff/cli/options/catalog_only.rb">catalog_only.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--color
--no-color </code></pre>
    </td>
    <td valign=top>
      Enable/disable colors in output
    </td>
    <td valign=top>
      Color printing option (<a href="../lib/octocatalog-diff/cli/options/color.rb">color.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--compare-file-text
--no-compare-file-text </code></pre>
    </td>
    <td valign=top>
      Compare text, not source location, of file resources
    </td>
    <td valign=top>
      When a file is specified with `source => 'puppet:///modules/something/foo.txt'`, remove
the 'source' attribute and populate the 'content' attribute with the text of the file.
This allows for a diff of the content, rather than a diff of the location, which is
what is most often desired. (<a href="../lib/octocatalog-diff/cli/options/compare_file_text.rb">compare_file_text.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>-d
--debug
--no-debug </code></pre>
    </td>
    <td valign=top>
      Print debugging messages to STDERR
    </td>
    <td valign=top>
      Debugging option (<a href="../lib/octocatalog-diff/cli/options/debug.rb">debug.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--debug-bootstrap </code></pre>
    </td>
    <td valign=top>
      Print debugging output for bootstrap script
    </td>
    <td valign=top>
      Option to print debugging output for the bootstrap script in addition to the normal
debugging output. Note that `--debug` must also be enabled for this option to have
any effect. (<a href="../lib/octocatalog-diff/cli/options/debug_bootstrap.rb">debug_bootstrap.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--default-header </code></pre>
    </td>
    <td valign=top>
      Print default header with output
    </td>
    <td valign=top>
      Provide ability to set custom header or to display no header at all (<a href="../lib/octocatalog-diff/cli/options/header.rb">header.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--display-datatype-changes
--no-display-datatype-changes </code></pre>
    </td>
    <td valign=top>
      Display changes in data type even when strings match
    </td>
    <td valign=top>
      Toggle on or off the display of data type changes when the string representation
is the same. For example with this enabled, '42' (the string) and 42 (the integer)
will be displayed as a difference. With this disabled, this is not displayed as a
difference. (<a href="../lib/octocatalog-diff/cli/options/display_datatype_changes.rb">display_datatype_changes.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--display-detail-add
--no-display-detail-add </code></pre>
    </td>
    <td valign=top>
      Display parameters and other details for added resources
    </td>
    <td valign=top>
      Provide ability to display details of 'added' resources in the output. (<a href="../lib/octocatalog-diff/cli/options/display_detail_add.rb">display_detail_add.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--display-source
--no-display-source </code></pre>
    </td>
    <td valign=top>
      Show source file and line for each difference
    </td>
    <td valign=top>
      Display source filename and line number for diffs (<a href="../lib/octocatalog-diff/cli/options/display_source_file_line.rb">display_source_file_line.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--enc PATH</code></pre>
    </td>
    <td valign=top>
      Path to ENC script, relative to checkout directory or absolute
    </td>
    <td valign=top>
      Path to external node classifier, relative to the base directory of the checkout. (<a href="../lib/octocatalog-diff/cli/options/enc.rb">enc.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--fact-file FILENAME</code></pre>
    </td>
    <td valign=top>
      Fact file to use instead of node lookup
    </td>
    <td valign=top>
      Allow an existing fact file to be provided, to avoid pulling facts from PuppetDB. (<a href="../lib/octocatalog-diff/cli/options/fact_file.rb">fact_file.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--facts-terminus STRING</code></pre>
    </td>
    <td valign=top>
      Facts terminus: one of yaml, facter
    </td>
    <td valign=top>
      Get the facts terminus. Generally this is 'yaml' and a fact file will be loaded from PuppetDB or
elsewhere in the environment. However it can be set to 'facter' which will run facter on the host
on which this is running. (<a href="../lib/octocatalog-diff/cli/options/facts_terminus.rb">facts_terminus.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--filters FILTER1[,FILTER2[,...]]</code></pre>
    </td>
    <td valign=top>
      Filters to apply
    </td>
    <td valign=top>
      Specify one or more filters to apply to the results of the catalog difference.
For a list of available filters and further explanation, please refer to
<a href="advanced-filter.md">Filtering results</a>. (<a href="../lib/octocatalog-diff/cli/options/filters.rb">filters.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>-f FROM_BRANCH
--from FROM_BRANCH</code></pre>
    </td>
    <td valign=top>
      Branch you are coming from
    </td>
    <td valign=top>
      Set the 'from' and 'to' branches, which is used to compile catalogs. A branch of '.' means to use
the current contents of the base code directory without any git checkouts. (<a href="../lib/octocatalog-diff/cli/options/to_from_branch.rb">to_from_branch.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--from-catalog FILENAME</code></pre>
    </td>
    <td valign=top>
      Use a pre-compiled catalog 'from'
    </td>
    <td valign=top>
      If pre-compiled catalogs are available, these can be used to short-circuit the build process.
These files must exist and be in Puppet catalog format. (<a href="../lib/octocatalog-diff/cli/options/existing_catalogs.rb">existing_catalogs.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--from-enc PATH</code></pre>
    </td>
    <td valign=top>
      Path to ENC script (for the from catalog only)
    </td>
    <td valign=top>
      Path to external node classifier, relative to the base directory of the checkout. (<a href="../lib/octocatalog-diff/cli/options/enc.rb">enc.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--from-puppetdb
--no-from-puppetdb </code></pre>
    </td>
    <td valign=top>
      Pull "from" catalog from PuppetDB instead of compiling
    </td>
    <td valign=top>
      Set --from-puppetdb to pull most recent catalog from PuppetDB instead of compiling (<a href="../lib/octocatalog-diff/cli/options/from_puppetdb.rb">from_puppetdb.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--header STRING</code></pre>
    </td>
    <td valign=top>
      Specify header for output
    </td>
    <td valign=top>
      Provide ability to set custom header or to display no header at all (<a href="../lib/octocatalog-diff/cli/options/header.rb">header.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--hiera-config PATH</code></pre>
    </td>
    <td valign=top>
      Relative path to hiera YAML file
    </td>
    <td valign=top>
      Specify a relative path to the Hiera yaml file (<a href="../lib/octocatalog-diff/cli/options/hiera_config.rb">hiera_config.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--hiera-path PATH</code></pre>
    </td>
    <td valign=top>
      Path to hiera data directory, relative to top directory of repository
    </td>
    <td valign=top>
      Specify the path to the Hiera data directory (relative to the top level Puppet checkout). For Puppet Enterprise and the
Puppet control repo template, the value of this should be 'hieradata', which is the default. (<a href="../lib/octocatalog-diff/cli/options/hiera_path.rb">hiera_path.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--hiera-path-strip PATH</code></pre>
    </td>
    <td valign=top>
      Path prefix to strip when munging hiera.yaml
    </td>
    <td valign=top>
      Specify the path to strip off the datadir to munge hiera.yaml file (<a href="../lib/octocatalog-diff/cli/options/hiera_path_strip.rb">hiera_path_strip.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>-n HOSTNAME
--hostname HOSTNAME</code></pre>
    </td>
    <td valign=top>
      Use PuppetDB facts from last run of hostname
    </td>
    <td valign=top>
      Set hostname, which is used to look up facts in PuppetDB, and in the header of diff display. (<a href="../lib/octocatalog-diff/cli/options/hostname.rb">hostname.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--ignore "Type1[Title1],Type2[Title2],..."</code></pre>
    </td>
    <td valign=top>
      More resources to ignore in format type[title]
    </td>
    <td valign=top>
      Options used when comparing catalogs - set ignored changes. (<a href="../lib/octocatalog-diff/cli/options/ignore.rb">ignore.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--ignore-attr "attr1,attr2,..."</code></pre>
    </td>
    <td valign=top>
      Attributes to ignore
    </td>
    <td valign=top>
      Specify attributes to ignore (<a href="../lib/octocatalog-diff/cli/options/ignore_attr.rb">ignore_attr.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--ignore-tags STRING1[,STRING2[,...]]</code></pre>
    </td>
    <td valign=top>
      Specify tags to ignore
    </td>
    <td valign=top>
      Provide ability to set one or more tags, which will cause catalog-diff
to ignore any changes for any defined type where this tag is set. (<a href="../lib/octocatalog-diff/cli/options/ignore_tags.rb">ignore_tags.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--include-tags
--no-include-tags </code></pre>
    </td>
    <td valign=top>
      Include changes to tags in the diff output
    </td>
    <td valign=top>
      Options used when comparing catalogs - tags are generally ignored; you can un-ignore them. (<a href="../lib/octocatalog-diff/cli/options/include_tags.rb">include_tags.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--master-cache-branch BRANCH</code></pre>
    </td>
    <td valign=top>
      Branch to cache
    </td>
    <td valign=top>
      Allow override of the branch that is cached. This defaults to 'origin/master'. (<a href="../lib/octocatalog-diff/cli/options/master_cache_branch.rb">master_cache_branch.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--no-enc </code></pre>
    </td>
    <td valign=top>
      Disable ENC
    </td>
    <td valign=top>
      Path to external node classifier, relative to the base directory of the checkout. (<a href="../lib/octocatalog-diff/cli/options/enc.rb">enc.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--no-header </code></pre>
    </td>
    <td valign=top>
      Do not print a header
    </td>
    <td valign=top>
      Provide ability to set custom header or to display no header at all (<a href="../lib/octocatalog-diff/cli/options/header.rb">header.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--no-hiera-config </code></pre>
    </td>
    <td valign=top>
      Disable hiera config file installation
    </td>
    <td valign=top>
      Specify a relative path to the Hiera yaml file (<a href="../lib/octocatalog-diff/cli/options/hiera_config.rb">hiera_config.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--no-hiera-path </code></pre>
    </td>
    <td valign=top>
      Do not use any default hiera path settings
    </td>
    <td valign=top>
      Specify the path to the Hiera data directory (relative to the top level Puppet checkout). For Puppet Enterprise and the
Puppet control repo template, the value of this should be 'hieradata', which is the default. (<a href="../lib/octocatalog-diff/cli/options/hiera_path.rb">hiera_path.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--no-hiera-path-strip </code></pre>
    </td>
    <td valign=top>
      Do not use any default hiera path strip settings
    </td>
    <td valign=top>
      Specify the path to strip off the datadir to munge hiera.yaml file (<a href="../lib/octocatalog-diff/cli/options/hiera_path_strip.rb">hiera_path_strip.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--no-ignore-tags </code></pre>
    </td>
    <td valign=top>
      Disable ignoring based on tags
    </td>
    <td valign=top>
      Provide ability to set one or more tags, which will cause catalog-diff
to ignore any changes for any defined type where this tag is set. (<a href="../lib/octocatalog-diff/cli/options/ignore_tags.rb">ignore_tags.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>-o FILENAME
--output-file FILENAME</code></pre>
    </td>
    <td valign=top>
      Output results into FILENAME
    </td>
    <td valign=top>
      Output file option (<a href="../lib/octocatalog-diff/cli/options/output_file.rb">output_file.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--output-format FORMAT</code></pre>
    </td>
    <td valign=top>
      Output format: text,json,legacy_json
    </td>
    <td valign=top>
      Output format option. 'text' is human readable text, 'json' is an array of differences
identified by human readable keys (the preferred octocatalog-diff 1.x format), and 'legacy_json' is an
array of differences, where each difference is an array (the octocatalog-diff 0.x format). (<a href="../lib/octocatalog-diff/cli/options/output_format.rb">output_format.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--parallel
--no-parallel </code></pre>
    </td>
    <td valign=top>
      Enable or disable parallel processing
    </td>
    <td valign=top>
      Disable or enable parallel processing of catalogs. (<a href="../lib/octocatalog-diff/cli/options/parallel.rb">parallel.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--parser PARSER_NAME</code></pre>
    </td>
    <td valign=top>
      Specify parser (default, future)
    </td>
    <td valign=top>
      Enable future parser for both branches or for just one (<a href="../lib/octocatalog-diff/cli/options/parser.rb">parser.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--parser-from PARSER_NAME</code></pre>
    </td>
    <td valign=top>
      Specify parser (default, future)
    </td>
    <td valign=top>
      Enable future parser for both branches or for just one (<a href="../lib/octocatalog-diff/cli/options/parser.rb">parser.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--parser-to PARSER_NAME</code></pre>
    </td>
    <td valign=top>
      Specify parser (default, future)
    </td>
    <td valign=top>
      Enable future parser for both branches or for just one (<a href="../lib/octocatalog-diff/cli/options/parser.rb">parser.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--pass-env-vars VAR1[,VAR2[,...]]</code></pre>
    </td>
    <td valign=top>
      Environment variables to pass
    </td>
    <td valign=top>
      One or more environment variables that should be made available to the Puppet binary when parsing
the catalog. For example, --pass-env-vars FOO,BAR will make the FOO and BAR environment variables
available. Setting these variables is your responsibility outside of octocatalog-diff. (<a href="../lib/octocatalog-diff/cli/options/pass_env_vars.rb">pass_env_vars.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--pe-enc-ssl-ca FILENAME</code></pre>
    </td>
    <td valign=top>
      CA certificate that signed the ENC API certificate
    </td>
    <td valign=top>
      Specify the CA certificate for the Puppet Enterprise ENC. If specified, this will enable SSL verification
that the certificate being presented has been signed by this CA, and that the common name
matches the name you are using to connecting. (<a href="../lib/octocatalog-diff/cli/options/pe_enc_ssl_ca.rb">pe_enc_ssl_ca.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--pe-enc-ssl-client-cert FILENAME</code></pre>
    </td>
    <td valign=top>
      SSL client certificate to connect to PE ENC
    </td>
    <td valign=top>
      Specify the client certificate for connecting to the Puppet Enterprise ENC. This must be specified along with
--pe-enc-ssl-client-key in order to work. (<a href="../lib/octocatalog-diff/cli/options/pe_enc_ssl_client_cert.rb">pe_enc_ssl_client_cert.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--pe-enc-ssl-client-key FILENAME</code></pre>
    </td>
    <td valign=top>
      SSL client key to connect to PE ENC
    </td>
    <td valign=top>
      Specify the client key for connecting to Puppet Enterprise ENC. This must be specified along with
--pe-enc-ssl-client-cert in order to work. (<a href="../lib/octocatalog-diff/cli/options/pe_enc_ssl_client_key.rb">pe_enc_ssl_client_key.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--pe-enc-token TOKEN</code></pre>
    </td>
    <td valign=top>
      Token to access the Puppet Enterprise ENC API
    </td>
    <td valign=top>
      Specify the access token to access the Puppet Enterprise ENC. Refer to
https://docs.puppet.com/pe/latest/nc_forming_requests.html#authentication for
details on generating and obtaining a token. Use this option to specify the text
of the token. (Use --pe-enc-token-file to read the content of the token from a file.) (<a href="../lib/octocatalog-diff/cli/options/pe_enc_token.rb">pe_enc_token.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--pe-enc-token-file PATH</code></pre>
    </td>
    <td valign=top>
      Path containing token for PE node classifier, relative or absolute
    </td>
    <td valign=top>
      Specify the access token to access the Puppet Enterprise ENC. Refer to
https://docs.puppet.com/pe/latest/nc_forming_requests.html#authentication for
details on generating and obtaining a token. Use this option if the token is stored
in a file, to read the content of the token from the file. (<a href="../lib/octocatalog-diff/cli/options/pe_enc_token_file.rb">pe_enc_token_file.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--pe-enc-url URL</code></pre>
    </td>
    <td valign=top>
      Base URL for Puppet Enterprise ENC endpoint
    </td>
    <td valign=top>
      Specify the URL to the Puppet Enterprise ENC API. By default, the node classifier service
listens on port 4433 and all endpoints are relative to the /classifier-api/ path. That means
the likely value for this option will be something like:
https://your-pe-console-server:4433/classifier-api (<a href="../lib/octocatalog-diff/cli/options/pe_enc_url.rb">pe_enc_url.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--preserve-environments
--no-preserve-environments </code></pre>
    </td>
    <td valign=top>
      Enable or disable environment preservation
    </td>
    <td valign=top>
      Preserve the `environments` directory from the repository when compiling the catalog. Likely
requires some combination of `--to-environment`, `--from-environment`, and/or `--create-symlinks`
to work correctly. (<a href="../lib/octocatalog-diff/cli/options/preserve_environments.rb">preserve_environments.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--puppetdb-api-version N</code></pre>
    </td>
    <td valign=top>
      Version of PuppetDB API (3 or 4)
    </td>
    <td valign=top>
      Specify the API version to use for the PuppetDB. The current values supported are '3' or '4', and '4' is
the default. (<a href="../lib/octocatalog-diff/cli/options/puppetdb_api_version.rb">puppetdb_api_version.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--puppetdb-ssl-ca FILENAME</code></pre>
    </td>
    <td valign=top>
      CA certificate that signed the PuppetDB certificate
    </td>
    <td valign=top>
      Specify the CA certificate for PuppetDB. If specified, this will enable SSL verification
that the certificate being presented has been signed by this CA, and that the common name
matches the name you are using to connecting. (<a href="../lib/octocatalog-diff/cli/options/puppetdb_ssl_ca.rb">puppetdb_ssl_ca.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--puppetdb-ssl-client-cert FILENAME</code></pre>
    </td>
    <td valign=top>
      SSL client certificate to connect to PuppetDB
    </td>
    <td valign=top>
      Specify the client certificate for connecting to PuppetDB. This must be specified along with
--puppetdb-ssl-client-key in order to work. (<a href="../lib/octocatalog-diff/cli/options/puppetdb_ssl_client_cert.rb">puppetdb_ssl_client_cert.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--puppetdb-ssl-client-key FILENAME</code></pre>
    </td>
    <td valign=top>
      SSL client key to connect to PuppetDB
    </td>
    <td valign=top>
      Specify the client key for connecting to PuppetDB. This must be specified along with
--puppetdb-ssl-client-cert in order to work. (<a href="../lib/octocatalog-diff/cli/options/puppetdb_ssl_client_key.rb">puppetdb_ssl_client_key.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--puppetdb-ssl-client-password PASSWORD</code></pre>
    </td>
    <td valign=top>
      Password for SSL client key to connect to PuppetDB
    </td>
    <td valign=top>
      Specify the password for a PEM or PKCS12 private key on the command line.
Note that `--puppetdb-ssl-client-password-file` is slightly more secure because
the text of the password won't appear in the process list. (<a href="../lib/octocatalog-diff/cli/options/puppetdb_ssl_client_password.rb">puppetdb_ssl_client_password.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--puppetdb-ssl-client-password-file FILENAME</code></pre>
    </td>
    <td valign=top>
      Read password for SSL client key from a file
    </td>
    <td valign=top>
      Specify the password for a PEM or PKCS12 private key, by reading it from a file. (<a href="../lib/octocatalog-diff/cli/options/puppetdb_ssl_client_password_file.rb">puppetdb_ssl_client_password_file.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--puppetdb-url URL</code></pre>
    </td>
    <td valign=top>
      PuppetDB base URL
    </td>
    <td valign=top>
      Specify the base URL for PuppetDB. This will generally look like https://puppetdb.yourdomain.com:8081 (<a href="../lib/octocatalog-diff/cli/options/puppetdb_url.rb">puppetdb_url.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>-q
--quiet
--no-quiet </code></pre>
    </td>
    <td valign=top>
      Quiet (no status messages except errors)
    </td>
    <td valign=top>
      Quiet option (<a href="../lib/octocatalog-diff/cli/options/quiet.rb">quiet.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--retry-failed-catalog N</code></pre>
    </td>
    <td valign=top>
      Retry building a failed catalog N times
    </td>
    <td valign=top>
      Transient errors can cause catalog compilation problems. This adds an option to retry
a failed catalog multiple times before kicking out an error message. (<a href="../lib/octocatalog-diff/cli/options/retry_failed_catalog.rb">retry_failed_catalog.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--safe-to-delete-cached-master-dir PATH</code></pre>
    </td>
    <td valign=top>
      OK to delete cached master directory at this path
    </td>
    <td valign=top>
      By specifying a directory path here, you are explicitly giving permission to the program
to delete it if it believes it needs to be created (e.g., if the SHA has changed of the
cached directory). (<a href="../lib/octocatalog-diff/cli/options/safe_to_delete_cached_master_dir.rb">safe_to_delete_cached_master_dir.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--storeconfigs
--no-storeconfigs </code></pre>
    </td>
    <td valign=top>
      Enable integration with puppetdb for collected resources
    </td>
    <td valign=top>
      Set storeconfigs (integration with PuppetDB for collected resources) (<a href="../lib/octocatalog-diff/cli/options/storeconfigs.rb">storeconfigs.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--suppress-absent-file-details
--no-suppress-absent-file-details </code></pre>
    </td>
    <td valign=top>
      Suppress certain attributes of absent files
    </td>
    <td valign=top>
      If enabled, this option will suppress changes to certain attributes of a file, if the
file is specified to be 'absent' in the target catalog. Suppressed changes in this case
include user, group, mode, and content, because a removed file has none of those.
<i>This option is DEPRECATED; please use <code>--filters AbsentFile</code> instead.</i> (<a href="../lib/octocatalog-diff/cli/options/suppress_absent_file_details.rb">suppress_absent_file_details.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>-t TO_BRANCH
--to TO_BRANCH</code></pre>
    </td>
    <td valign=top>
      Branch you are going to
    </td>
    <td valign=top>
      Set the 'from' and 'to' branches, which is used to compile catalogs. A branch of '.' means to use
the current contents of the base code directory without any git checkouts. (<a href="../lib/octocatalog-diff/cli/options/to_from_branch.rb">to_from_branch.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--to-catalog FILENAME</code></pre>
    </td>
    <td valign=top>
      Use a pre-compiled catalog 'to'
    </td>
    <td valign=top>
      If pre-compiled catalogs are available, these can be used to short-circuit the build process.
These files must exist and be in Puppet catalog format. (<a href="../lib/octocatalog-diff/cli/options/existing_catalogs.rb">existing_catalogs.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--to-enc PATH</code></pre>
    </td>
    <td valign=top>
      Path to ENC script (for the to catalog only)
    </td>
    <td valign=top>
      Path to external node classifier, relative to the base directory of the checkout. (<a href="../lib/octocatalog-diff/cli/options/enc.rb">enc.rb</a>)
    </td>
  </tr>

  <tr>
    <td valign=top>
      <pre><code>--validate-references
--no-validate-references </code></pre>
    </td>
    <td valign=top>
      References to validate
    </td>
    <td valign=top>
      Confirm that each `before`, `require`, `subscribe`, and/or `notify` points to a valid
resource in the catalog. This value should be specified as an array of which of these
parameters are to be checked. (<a href="../lib/octocatalog-diff/cli/options/validate_references.rb">validate_references.rb</a>)
    </td>
  </tr>

</table>

## Using these options in API calls

Most of these options can also be used when making calls to the [API](/doc/dev/api.md).

Generally, parameters for the API are named corresponding to the names of the command line parameters, with dashes (`-`) converted to underscores (`_`). For example, the command line option `--hiera-config` is passed to the API as the symbol `:hiera_config`.

Each of the options above has a link to the source file where it is declared, should you wish to review the specific parameter names and data structures that are being set.