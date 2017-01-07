# frozen_string_literal: true

# Specify the client certificate for connecting to the Puppet Enterprise ENC. This must be specified along with
# --pe-enc-ssl-client-key in order to work.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:pe_enc_ssl_client_cert) do
  has_weight 353

  def parse(parser, options)
    parser.on('--pe-enc-ssl-client-cert FILENAME', 'SSL client certificate to connect to PE ENC') do |x|
      raise Errno::ENOENT, "--pe-enc-ssl-client-cert #{x} does not point to a valid file" unless File.file?(x)
      options[:pe_enc_ssl_client_cert] = File.read(x)
    end
  end
end
