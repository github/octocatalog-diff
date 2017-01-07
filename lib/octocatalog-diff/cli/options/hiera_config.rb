# frozen_string_literal: true

# Specify a relative path to the Hiera yaml file
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:hiera_config) do
  has_weight 180

  def parse(parser, options)
    parser.on('--hiera-config PATH', 'Relative path to hiera YAML file') do |path_in|
      raise ArgumentError, '--no-hiera-config incompatible with --hiera-config' if options[:no_hiera_config]
      options[:hiera_config] = path_in
    end

    parser.on('--no-hiera-config', 'Disable hiera config file installation') do
      raise ArgumentError, '--no-hiera-config incompatible with --hiera-config' if options[:hiera_config]
      options[:no_hiera_config] = true
    end
  end
end
