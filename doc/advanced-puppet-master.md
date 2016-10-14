# Fetching catalogs from Puppet Master / PuppetServer

`octocatalog-diff` can fetch catalogs from a Puppet Master, PuppetServer, or Puppet Enterprise server by calling their HTTPS API, just as a node would when it fetches its catalog. For simplicity, this document will refer only to "Puppet Master" but unless otherwise noted, the instructions apply equally to the open source PuppetServer and Puppet Enterprise PuppetServer as well.

Please note the following caveats:

0. This method will put some load on your Puppet Master to build the catalog. Depending on how you use `octocatalog-diff` you should ensure that this extra load will not overwhelm your Puppet Master (especially if you create a "thundering herd" by launching several instances of `octocatalog-diff` simultaneously).

0. You will need to deploy your Puppet code to an environment on your Puppet Master prior to running `octocatalog-diff` for that environment. `octocatalog-diff` does not deploy code for you.

0. You will need to configure authorization for one or more whitelisted certificates on your Puppet Master. The default permissions allow a node to retrieve its own catalog via the API, but you need a certificate for `octocatalog-diff` that permits it to retrieve any catalog. See the [Certificate authorization](#certificate-authorization) section below.

## Command line options

The following command line options are used to retrieve a catalog from a Puppet Master:

| Option | Description |
| ------ | ----------- |
| `-f ENVIRONMENT` | Environment name to use for the "from" catalog |
| `-t ENVIRONMENT` | Environment name to use for the "to" catalog |
| `--puppet-master HOSTNAME:PORT | The hostname and port number of the Puppet Master. (By default the port used by Puppet Master is 8140.) |
| `--puppet-master-api-version VERSION | The API version used by the Puppet Master. API versions 2 and 3 are supported. Puppet Master 3.x uses API version 2, and the PuppetServer for Puppet 4.x uses API version 3. By default, API version 3 is used, so you only need to set this option if you are using Puppet Master 3.x. |
| `--puppet-master-ssl-ca PATH` | Path to the CA certificate (public portion of certificate only) for your Puppet Master. This file will be on your Puppet Master and all Puppet agents. You can find it by running `puppet config print cacert` on any Puppet-managed host. |
| `--puppet-master-ssl-client-cert PATH` | Path to the client certificate. Please see the section below on certificate authentication. |
| `--puppet-master-ssl-client-key PATH` | Path to the client private key. Please see the section below on certificate authentication. |

If you wish to use a different Puppet Master to compile the "to" and "from" catalogs, you may prefix any of the `--puppet-master...` options with `to` or `from`. For example, perhaps you are testing an upgrade from Puppet 3.x to 4.x. You could use:

```
... --from-puppet-master puppet3-x.yourdomain.com:8140 --from-puppet-master-api-version 2 --to-puppet-master puppet4-x.yourdomain.com:8140 ...
```

It is possible to "mix and match" catalog generation methods. For example, you could retrieve a "from" catalog from a Puppet Master using `--from-puppet-master` while compiling a "to" catalog from local code. Please note that some enhanced options of `octocatalog-diff`, such as comparing file text instead of file source location, may not be available for all such combinations.

## Certificate authorization

In order to use `octocatalog-diff` you will need to create one or more certificates that are empowered to retrieve all catalogs. This requires both creating the certificate, and reconfiguring your Puppet Master to expand the scope of authorization for that certificate.

Puppet Masters use the [legacy auth.conf file](https://docs.puppet.com/puppet/latest/reference/config_file_auth.html) and/or [PuppetServer auth.conf file](https://docs.puppet.com/puppetserver/latest/config_file_auth.html) to control access to HTTPS API.

In particular, the following entry in the legacy auth.conf permits a particular agent to retrieve its own catalog:

```
# allow nodes to retrieve their own catalog (ie their configuration)
path ~ ^/catalog/([^/]+)$
method find
allow $1
```

Please follow the instructions for the version of Puppet Master, PuppetServer, or Puppet Enterprise that you are using in order to generate and authorize the certificates.
