# frozen_string_literal: true

# Specify the Certificate Revocation List for PuppetDB SSL.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:puppetdb_ssl_crl) do
  has_weight 310
  order_within_weight 11

  def parse(parser, options)
    parser.on('--puppetdb-ssl-crl FILENAME', 'Certificate Revocation List provided by the Puppetserver') do |x|
      raise Errno::ENOENT, "--puppetdb-ssl-crl #{x} does not point to a valid file" unless File.file?(x)
      options[:puppetdb_ssl_crl] = x
    end
  end
end
