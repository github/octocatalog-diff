# Enabling storeconfigs for exported resources in PuppetDB

The "storeconfigs" setting in Puppet is a feature related to [exported resources](https://docs.puppet.com/puppet/latest/reference/lang_exported.html).

It is possible to enable the collection of exported resources when `octocatalog-diff` compiles catalogs, to give the most accurate representation possible of the catalogs before they are compared.

## Usage

When you provide the `--storeconfigs` command line option, or set `settings[:storeconfigs] = true` in the [configuration file](/doc/configuration.md), the following behavior is triggered:

  - `octocatalog-diff` will create a `puppetdb.conf` file in its temporary compilation directory, using the [PuppetDB configuration settings](/doc/configuration-puppetdb.md) that you have specified, either as command line parameters or in a configuration file.

  - `octocatalog-diff` will install the SSL client certificates you have provided for PuppetDB, if any, in its temporary compilation directory, so that Puppet will pick these up and use them to connect to PuppetDB. This allows SSL client authentication to PuppetDB. (Please note: Puppet *must* connect to PuppetDB over an SSL connection, although not necessarily an authenticated SSL connection.)

  - `octocatalog-diff` will create a `routes.yaml` file in its temporary compilation directory so that Puppet does not try to send fact data, resource data, or reports back to PuppetDB. We have done our best to make this connection be "read only" although we do encourage you to set up a separate, read-only port for PuppetDB to ensure this.

## Caveats

  - Beware of load this may cause on PuppetDB, especially if you run `octocatalog-diff` simultaneously in a CI environment. At GitHub, we run `octocatalog-diff` distributed across 8 CI nodes, each of which is capable of performing 16 simultaneous catalog compilations. We have noticed performance degradation or outages when a "thundering herd" of 128 catalog compilations hit PuppetDB at the same time, leading us to implement a layer of caching on top of PuppetDB.

  - `octocatalog-diff` compiles a "before" and "after" catalog in mostly parallel fashion, but it is possible that the order of operations happens as follows: (a) "before" catalog compiles; (b) something else writes updated data to PuppetDB; (c) "after" catalog compiles. In this case, there can be false differences reported in the output.

## Advanced configuration

This section contains tips on setting up a proxy in front of PuppetDB to control access and/or enable caching. You are not required to do this in order to use `--storeconfigs` but you may find these tips useful if simultaneous runs of `octocatalog-diff` put too much load on your PuppetDB instance.

### Making a read-only PuppetDB port

It is possible to create a read-only endpoint to PuppetDB by setting up a proxy that only allows the desired URLs. This ensures that the Puppet runs cannot submit fact data, resource data, or reports back to PuppetDB from `octocatalog-diff` runs. (As noted previously, we do set up `routes.yaml` to prevent this, but the strategy in this section provides an extra layer of security.)

To allow only the desired traffic, you should configure a port on your proxy that will pass to these URLs only:

  - /pdb/query
  - /pdb/meta

### Caching

To reduce the impact of a "thundering herd" of simultaneous `octocatalog-diff` runs, you can set up a caching proxy in front of the `/pdb/query` endpoint.

Here is a portion of the nginx configuration that has provided the best balance between performance and accuracy. We have chosen a 1 minute TTL on results, and incorporated the request body into the cache key. You will need to adjust and incorporate this configuration into your own nginx proxy.

```
upstream puppetdb {
    server localhost:8080;
}

proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=pdb_cache:10m max_size=25g inactive=2m;

server {
    listen 10.0.0.1:8082;

    # Some SSL settings omitted. Configure as per your own needs.
    ssl_client_certificate /etc/nginx/ca.crt
    ssl_verify_client on;

    proxy_cache_key "$scheme$proxy_host$uri$is_args$args|$request_body";

    deny all;

    location /pdb/query {
        proxy_cache pdb_cache;
        proxy_ignore_headers Cache-Control;
        proxy_cache_valid any 1m;
        proxy_pass http://puppetdb;
        proxy_redirect off;
        add_header X-Cache-Status $upstream_cache_status;
        allow all;
    }

    # Other settings omitted.
}
```
