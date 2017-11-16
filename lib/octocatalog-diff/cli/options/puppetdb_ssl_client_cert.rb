# frozen_string_literal: true

# Specify the client certificate for connecting to PuppetDB. This must be specified along with
# --puppetdb-ssl-client-key in order to work.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:puppetdb_ssl_client_cert) do
  has_weight 310
  order_within_weight 20

  def parse(parser, options)
    parser.on('--puppetdb-ssl-client-cert FILENAME', 'SSL client certificate to connect to PuppetDB') do |x|
      raise Errno::ENOENT, "--puppetdb-ssl-client-cert #{x} does not point to a valid file" unless File.file?(x)
      options[:puppetdb_ssl_client_cert] = File.read(x)
    end
  end
end
