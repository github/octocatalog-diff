# Fetching catalogs from Puppet Master / PuppetServer

`octocatalog-diff` can fetch catalogs from a Puppet Master, PuppetServer, or Puppet Enterprise server by calling their HTTPS API, just as a node would when it fetches its catalog. For simplicity, this document will refer only to "Puppet Master" but unless otherwise noted, the instructions apply equally to the open source PuppetServer and Puppet Enterprise PuppetServer as well.

Please note the following caveats:

0. This method will put some load on your Puppet Master to build the catalog. Depending on how you use `octocatalog-diff` you should ensure that this extra load will not overwhelm your Puppet Master (especially if you create a "thundering herd" by launching several instances of `octocatalog-diff` simultaneously).

0. You will need to deploy your Puppet code to an environment on your Puppet Master prior to running `octocatalog-diff` for that environment. `octocatalog-diff` does not deploy code for you.

0. You will need to configure authorization for one or more whitelisted certificates on your Puppet Master. The default permissions allow a node to retrieve its own catalog via the API, but you need a certificate for `octocatalog-diff` that permits it to retrieve any catalog. See the [Certificate authorization](#certificate-authorization) section below. If you are using Puppet Enterprise and use
the Puppet Master v4 API you may also use a Puppet Enterprise RBAC token. The user the token was
issued to will need the "Puppet Server Compile catalogs for remote nodes" permission.

0. If you are using the v2 or v3 APIs to compile catalogs against your PuppetServer those systems will store the facts you send in and catalogs generated in their PuppetDB instances. This can be dangerous if your environment depends on the use and collection of exported resources or an accurate representation of the fact data in PuppetDB. When using the v4 API the facts and catalogs will, by default, not be updated in PuppetDB as a result of the compile. If you wish to update them, you must specify one of the associated options to enable that behavior.

## Command line options

The following command line options are used to retrieve a catalog from a Puppet Master:

| Option | Description |
| ------ | ----------- |
| `-f ENVIRONMENT` | Environment name to use for the "from" catalog |
| `-t ENVIRONMENT` | Environment name to use for the "to" catalog |
| `--puppet-master HOSTNAME:PORT` | The hostname and port number of the Puppet Master. (By default the port used by Puppet Master is 8140.) |
| `--puppet-master-api-version VERSION` | The API version used by the Puppet Master. API versions 2, 3,and 4 are supported. Puppet Master 3.x uses API version 2, and the PuppetServer for Puppet 4.x uses API version 3. PuppetServer 6.3.0 introduced the v4 API. By default, API version 3 is used, so you only need to set this option if you are using Puppet Master 3.x or wish to use the newer v4 API. |
| `--puppet-master-ssl-ca PATH` | Path to the CA certificate (public portion of certificate only) for your Puppet Master. This file will be on your Puppet Master and all Puppet agents. You can find it by running `puppet config print cacert` on any Puppet-managed host. |
| `--puppet-master-ssl-client-cert PATH` | Path to the client certificate. Please see the section below on certificate authentication. This can be omitted if using PE RBAC token based auth with the v4 API. |
| `--puppet-master-ssl-client-key PATH` | Path to the client private key. Please see the section below on certificate authentication. This can be omitted if using PE RBAC token based auth with the v4 API. |
| `--puppet-master-token STRING` | A PE RBAC token used to authenticate a v4 catalog compile, in lieu of using certificate authentication. Please see the section below on token authentication. |
| `--puppet-master-token-file PATH` | A path to a file containing a PE RBAC token used to authenticate a v4 catalog compile, in lieu of using certificate authentication. If this and `--puppet-master-token` are both specified, `--puppet-master-token` will be used instead. Please see the section below on token authentication. |
| `--puppet-master-update-catalog` | When using the v4 API, instruct the PuppetServer to update the catalog generated from the compile in its PuppetDB instance. When using v2 and v3 APIs the catalog is always updated and this option is ignored. |
| `--puppet-master-update-facts` | When using the v4 API, instruct the PuppetServer to update the facts used during the compile in its PuppetDB instance. When using v2 and v3 APIs the facts are always updated and this option is ignored. |

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

## PE RBAC Token authorization

In newer versions of Puppet Enterprise you can authenticate using a valid PE RBAC token with appropriate permissions as long as it is authorized in the PuppetServer `auth.conf` file.

By default this permission is enabled and controlled by the `puppet_enterprise::master::tk_authz::allow_rbac_catalog_compile` Hiera setting.

The user the token was issued to must have the `puppetserver:compile_catalogs:*` permission.

Note: `octocatalog-diff` will automatically obscure any secrets marked as `Sensitive` when displaying differences, but the above RBAC permission does give uses the ability to retrieve catalogs with all secrets, even ones marked `Sensitive`, visible.
