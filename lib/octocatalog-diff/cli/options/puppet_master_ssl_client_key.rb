# frozen_string_literal: true

# Specify the SSL client key for Puppet Master. This makes it possible to authenticate with a
# client certificate keypair to the Puppet Master.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:puppet_master_ssl_client_key) do
  has_weight 320

  def parse(parser, options)
    OctocatalogDiff::Cli::Options.option_globally_or_per_branch(
      parser: parser,
      options: options,
      cli_name: 'puppet-master-ssl-client-key',
      option_name: 'puppet_master_ssl_client_key',
      desc: 'Full path to key file for SSL client auth to Puppet Master',
      validator: ->(x) { File.file?(x) || raise(Errno::ENOENT, "Suggested key #{x} does not exist") },
      translator: ->(x) { File.read(x) }
    )
  end
end
