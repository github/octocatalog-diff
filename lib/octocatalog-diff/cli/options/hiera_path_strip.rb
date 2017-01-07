# frozen_string_literal: true

# Specify the path to strip off the datadir to munge hiera.yaml file
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:hiera_path_strip) do
  has_weight 182

  def parse(parser, options)
    parser.on('--hiera-path-strip PATH', 'Path prefix to strip when munging hiera.yaml') do |path_in|
      if options.key?(:hiera_path) && options[:hiera_path] != :none
        raise ArgumentError, '--hiera-path and --hiera-path-strip are mutually exclusive'
      end

      if options[:hiera_path_strip] == :none
        raise ArgumentError, '--hiera-path-strip and --no-hiera-path-strip are mutually exclusive'
      end

      options[:hiera_path_strip] = path_in
    end

    parser.on('--no-hiera-path-strip', 'Do not use any default hiera path strip settings') do
      if options[:hiera_path_strip].is_a?(String)
        raise ArgumentError, '--hiera-path-strip and --no-hiera-path-strip are mutually exclusive'
      end
      options[:hiera_path_strip] = :none
    end
  end
end
