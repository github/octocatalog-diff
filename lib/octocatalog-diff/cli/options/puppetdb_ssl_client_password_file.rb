# frozen_string_literal: true

# Specify the password for a PEM or PKCS12 private key, by reading it from a file.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:puppetdb_ssl_client_password_file) do
  has_weight 310
  order_within_weight 37

  def parse(parser, options)
    parser.on('--puppetdb-ssl-client-password-file FILENAME', 'Read password for SSL client key from a file') do |x|
      raise Errno::ENOENT, "--puppetdb-ssl-client-password-file #{x} does not point to a valid file" unless File.file?(x)
      options[:puppetdb_ssl_client_password] = File.read(x)
    end
  end
end
