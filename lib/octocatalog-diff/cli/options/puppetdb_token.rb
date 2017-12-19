# frozen_string_literal: true

# Specify the PE RBAC token to access the PuppetDB API. Refer to
# https://puppet.com/docs/pe/latest/rbac/rbac_token_auth_intro.html#generate-a-token-using-puppet-access
# for details on generating and obtaining a token. Use this option to specify the text
# of the token. (Use --puppetdb-token-file to read the content of the token from a file.)
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:puppetdb_token) do
  has_weight 310

  def parse(parser, options)
    parser.on('--puppetdb-token TOKEN', 'Token to access the PuppetDB API') do |token|
      options[:puppetdb_token] = token
    end
  end
end
