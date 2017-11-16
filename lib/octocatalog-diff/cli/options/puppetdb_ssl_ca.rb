# frozen_string_literal: true

# Specify the CA certificate for PuppetDB. If specified, this will enable SSL verification
# that the certificate being presented has been signed by this CA, and that the common name
# matches the name you are using to connecting.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:puppetdb_ssl_ca) do
  has_weight 310
  order_within_weight 10

  def parse(parser, options)
    parser.on('--puppetdb-ssl-ca FILENAME', 'CA certificate that signed the PuppetDB certificate') do |x|
      raise Errno::ENOENT, "--puppetdb-ssl-ca #{x} does not point to a valid file" unless File.file?(x)
      options[:puppetdb_ssl_ca] = x
    end
  end
end
