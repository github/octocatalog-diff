# frozen_string_literal: true

# Specify the client key for connecting to Puppet Enterprise ENC. This must be specified along with
# --pe-enc-ssl-client-cert in order to work.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:pe_enc_ssl_client_key) do
  has_weight 354

  def parse(parser, options)
    parser.on('--pe-enc-ssl-client-key FILENAME', 'SSL client key to connect to PE ENC') do |x|
      raise Errno::ENOENT, "--pe-enc-ssl-client-key #{x} does not point to a valid file" unless File.file?(x)
      options[:pe_enc_ssl_client_key] = File.read(x)
    end
  end
end
