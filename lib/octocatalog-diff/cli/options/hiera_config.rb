# frozen_string_literal: true

# Specify a relative path to the Hiera yaml file
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:hiera_config) do
  has_weight 180

  def parse(parser, options)
    OctocatalogDiff::Cli::Options.option_globally_or_per_branch(
      parser: parser,
      options: options,
      cli_name: 'hiera-config',
      option_name: 'hiera_config',
      desc: 'Full or relative path to global Hiera configuration file',
      post_process: lambda do |opts|
        raise ArgumentError, '--no-hiera-config incompatible with --hiera-config' if opts[:no_hiera_config]
      end
    )

    parser.on('--no-hiera-config', 'Disable hiera config file installation') do
      if options[:to_hiera_config] || options[:from_hiera_config]
        raise ArgumentError, '--no-hiera-config incompatible with --hiera-config'
      end
      options[:no_hiera_config] = true
    end
  end
end
