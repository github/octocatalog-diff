# frozen_string_literal: true

# Specify the CA certificate for the Puppet Enterprise ENC. If specified, this will enable SSL verification
# that the certificate being presented has been signed by this CA, and that the common name
# matches the name you are using to connecting.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:pe_enc_ssl_ca) do
  has_weight 352

  def parse(parser, options)
    parser.on('--pe-enc-ssl-ca FILENAME', 'CA certificate that signed the ENC API certificate') do |x|
      raise Errno::ENOENT, "--pe-enc-ssl-ca #{x} does not point to a valid file" unless File.file?(x)
      options[:pe_enc_ssl_ca] = x
    end
  end
end
