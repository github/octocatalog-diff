# frozen_string_literal: true

# Specify the access token to access the Puppet Enterprise ENC. Refer to
# https://docs.puppet.com/pe/latest/nc_forming_requests.html#authentication for
# details on generating and obtaining a token. Use this option to specify the text
# of the token. (Use --pe-enc-token-file to read the content of the token from a file.)
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:pe_enc_token) do
  has_weight 351

  def parse(parser, options)
    parser.on('--pe-enc-token TOKEN', 'Token to access the Puppet Enterprise ENC API') do |token|
      options[:pe_enc_token] = token
    end
  end
end
