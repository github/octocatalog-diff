# frozen_string_literal: true

# Specify the access token to access the Puppet Enterprise ENC. Refer to
# https://docs.puppet.com/pe/latest/nc_forming_requests.html#authentication for
# details on generating and obtaining a token. Use this option if the token is stored
# in a file, to read the content of the token from the file.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:pe_enc_token_file) do
  has_weight 351

  def parse(parser, options)
    parser.on('--pe-enc-token-file PATH', 'Path containing token for PE node classifier, relative or absolute') do |x|
      proposed_token_path = x.start_with?('/') ? x : File.join(options[:basedir], x)
      raise Errno::ENOENT, "Provided token (#{proposed_token_path}) does not exist" unless File.file?(proposed_token_path)
      options[:pe_enc_token] = File.read(proposed_token_path)
    end
  end
end
