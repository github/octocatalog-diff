# Specify the path to strip off the datadir to munge hiera.yaml file
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::CatalogDiff::Cli::Options::Option.newoption(:hiera_path_strip) do
  has_weight 182

  def parse(parser, options)
    parser.on('--hiera-path-strip PATH', 'Path prefix to strip when munging hiera.yaml') do |path_in|
      raise ArgumentError, '--hiera-path and --hiera-path-strip are mutually exclusive' if options.key?(:hiera_path)

      options[:hiera_path_strip] = path_in
    end
  end
end
