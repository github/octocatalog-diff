# frozen_string_literal: true

# Specify the password for a PEM or PKCS12 private key on the command line.
# Note that `--puppetdb-ssl-client-password-file` is slightly more secure because
# the text of the password won't appear in the process list.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:puppetdb_ssl_client_cert) do
  has_weight 310

  def parse(parser, options)
    parser.on('--puppetdb-ssl-client-password PASSWORD', 'Password for SSL client key to connect to PuppetDB') do |x|
      options[:puppetdb_ssl_client_password] = x
    end
  end
end
