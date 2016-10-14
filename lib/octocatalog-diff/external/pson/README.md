# PSON

Puppet uses a JSON variant called PSON to serialize data (e.g. facts) transmitting to/from a Puppet master.

Documentation for PSON can be found here:

    https://docs.puppet.com/puppet/4.6/reference/http_api/pson.html

The code in this directory was taken directly from Puppet and can be found at:

    https://github.com/puppetlabs/puppet/tree/master/lib/puppet/external/pson

If you have found this code to deal with Puppet serialization, you should probably take the original and most up-to-date code from Puppet at the location above.

This code contains the following modifications:

- Change the `require` statements to `require_relative` statements so they work in this gem's directory structure
- Change `$MATCH` to `$&` because `$MATCH` is undefined without `require 'english`` or equivalent

This code is licensed by Puppet under the Apache 2.0 license. A copy of the Puppet license can be found in this directory.
