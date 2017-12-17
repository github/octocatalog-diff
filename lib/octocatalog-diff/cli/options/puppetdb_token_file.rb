# frozen_string_literal: true

# Specify the PE RBAC token to access the PuppetDB API. Refer to
# https://puppet.com/docs/pe/latest/rbac/rbac_token_auth_intro.html#generate-a-token-using-puppet-access
# for details on generating and obtaining a token. Use this option to specify the text
# in a file, to read the content of the token from the file.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:puppetdb_token_file) do
  has_weight 310

  def parse(parser, options)
    parser.on('--puppetdb-token-file PATH', 'Path containing token for PuppetDB API, relative or absolute') do |x|
      proposed_token_path = x.start_with?('/') ? x : File.join(options[:basedir], x)
      unless File.file?(proposed_token_path)
        raise Errno::ENOENT, "Provided PuppetDB API token (#{proposed_token_path}) does not exist"
      end
      options[:puppetdb_token] = File.read(proposed_token_path)
    end
  end
end
