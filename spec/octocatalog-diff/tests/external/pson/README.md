# PSON

Puppet uses a JSON variant called PSON to serialize data (e.g. facts) transmitting to/from a Puppet master.

Documentation for PSON can be found here:

    https://docs.puppet.com/puppet/4.6/reference/http_api/pson.html

The code in this directory was taken directly from Puppet and can be found at:

    https://github.com/puppetlabs/puppet/tree/master/spec/unit/external

If you have found this code to deal with Puppet serialization, you should probably take the original and most up-to-date code from Puppet at the location above.

This code is used without modifications, except to change the `require` statements to use the octocatalog-diff spec helper so they work in this gem's directory structure, and to `pending` the "arbitrary binary data" test which does not seem to pass.

This code is licensed by Puppet under the Apache 2.0 license. A copy of the Puppet license can be found in this directory.
