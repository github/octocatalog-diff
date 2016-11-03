# Specify the path to the Hiera data directory (relative to the top level Puppet checkout). For Puppet Enterprise and the
# Puppet control repo template, the value of this should be 'hieradata', which is the default.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::CatalogDiff::Cli::Options::Option.newoption(:hiera_path) do
  has_weight 181

  def parse(parser, options)
    parser.on('--hiera-path PATH', 'Path to hiera data directory, relative to top directory of repository') do |path_in|
      raise ArgumentError, '--hiera-path and --hiera-path-strip are mutually exclusive' if options.key?(:hiera_path_strip)

      options[:hiera_path] = path_in

      if options[:hiera_path].start_with?('/')
        raise ArgumentError, '--hiera-path PATH must be a relative path not an absolute path'
      end

      options[:hiera_path].sub!(%r{/+$}, '')
      raise ArgumentError, '--hiera-path must not be empty' if options[:hiera_path].empty?
    end
  end
end
