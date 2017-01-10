# Puppet Enterprise node classification service

If you are using Puppet Enterprise, `octocatalog-diff` can use the node classifier service API instead of an external node classifier.

## Basics

To use the Puppet Enterprise node classifier service instead of an ENC, you must supply the URL to your node classifier service API endpoint, and either an authentication token or a whilelisted SSL client keypair. It is recommended to supply the SSL Certificate Authority (CA) file as well, to verify the identity of the server to which you are connecting.

To use Puppet Enterprise node classifier service with an authentication token:

```
octocatalog-diff \
  --pe-enc-url https://your.pe.console.server:4433/classifier-api \
  --pe-enc-token-file /path/to/token/file.txt \
  --pe-enc-ssl-ca /path/to/ca.crt \
  [other options]
```

To use Puppet Enterprise node classifier service with a whitelisted SSL client keypair:

```
octocatalog-diff \
  --pe-enc-url https://your.pe.console.server:4433/classifier-api \
  --pe-enc-ssl-ca /path/to/ca.crt \
  --pe-enc-ssl-client-cert /path/to/client.crt \
  --pe-enc-ssl-client-key /path/to/client.key \
  [other options]
```

## Details

### Requirements

- Your PE console server must be accessible to the machine from which you are running `octocatalog-diff` on the appropriate port (by default, 4433). This port is *not* required to run Puppet agents, so it's possible that you have it firewalled off.

### Authentication token

Please see [Authentication token](https://docs.puppet.com/pe/latest/nc_forming_requests.html#authentication-token) in the official Puppet documentation.

The referenced document contains links to generate a token with the `puppet-access` command.

Note that if you wish to hard-code an authentication token in your [configuration file](/doc/configuration.md), the internal variable key is `:pe_enc_token` and the content is a string containing the entire token. (The `--pe-enc-token-file` option simply reads the provided file and stores the content in the `:pe_enc_token` key. See [source](/lib/octocatalog-diff/cli/options/pe_enc_token_file.rb).)

### SSL client keypair

If you wish to use a SSL client keypair instead of a token, please see [Whilelisted certificate](https://docs.puppet.com/pe/latest/nc_forming_requests.html#whitelisted-certificate) in the official Puppet documentation.

The referenced document contains instructions to add the certificate name to the whitelist file and restart the necessary services.

### Further reading

[Puppet documentation on node classifier endpoints](https://docs.puppet.com/pe/latest/nc_index.html)
