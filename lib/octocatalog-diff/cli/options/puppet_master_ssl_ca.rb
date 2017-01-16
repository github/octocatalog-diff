# frozen_string_literal: true

# Specify the CA certificate for Puppet Master. If specified, this will enable SSL verification
# that the certificate being presented has been signed by this CA, and that the common name
# matches the name you are using to connecting.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:puppet_master_ssl_ca) do
  has_weight 320

  def parse(parser, options)
    OctocatalogDiff::Cli::Options.option_globally_or_per_branch(
      parser: parser,
      options: options,
      cli_name: 'puppet-master-ssl-ca',
      option_name: 'puppet_master_ssl_ca',
      desc: 'Full path to CA certificate that signed the Puppet Master certificate',
      validator: ->(x) { File.file?(x) || raise(Errno::ENOENT, "SSL CA cert #{x} does not exist") }
    )
  end
end
