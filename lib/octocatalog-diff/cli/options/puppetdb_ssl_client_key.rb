# frozen_string_literal: true

# Specify the client key for connecting to PuppetDB. This must be specified along with
# --puppetdb-ssl-client-cert in order to work.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:puppetdb_ssl_client_key) do
  has_weight 310
  order_within_weight 30

  def parse(parser, options)
    parser.on('--puppetdb-ssl-client-key FILENAME', 'SSL client key to connect to PuppetDB') do |x|
      raise Errno::ENOENT, "--puppetdb-ssl-client-key #{x} does not point to a valid file" unless File.file?(x)
      options[:puppetdb_ssl_client_key] = File.read(x)
    end
  end
end
