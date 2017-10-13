# frozen_string_literal: true

# Specify the path to strip off the datadir to munge hiera.yaml file
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:hiera_path_strip) do
  has_weight 182

  def parse(parser, options)
    OctocatalogDiff::Cli::Options.option_globally_or_per_branch(
      parser: parser,
      options: options,
      cli_name: 'hiera-path-strip',
      option_name: 'hiera_path_strip',
      desc: 'Path prefix to strip when munging hiera.yaml',
      post_process: lambda do |opts|
        if opts.key?(:to_hiera_path) && opts[:to_hiera_path] != :none
          if opts.key?(:to_hiera_path_strip) && opts[:to_hiera_path_strip] != :none
            raise ArgumentError, '--hiera-path and --hiera-path-strip are mutually exclusive'
          end
        end
        if opts.key?(:from_hiera_path) && opts[:from_hiera_path] != :none
          if opts.key?(:from_hiera_path_strip) && opts[:from_hiera_path_strip] != :none
            raise ArgumentError, '--hiera-path and --hiera-path-strip are mutually exclusive'
          end
        end
        if opts[:to_hiera_path_strip] == :none || opts[:from_hiera_path_strip] == :none
          raise ArgumentError, '--hiera-path-strip and --no-hiera-path-strip are mutually exclusive'
        end
      end
    )

    parser.on('--no-hiera-path-strip', 'Do not use any default hiera path strip settings') do
      if options[:to_hiera_path_strip].is_a?(String) || options[:from_hiera_path_strip].is_a?(String)
        raise ArgumentError, '--hiera-path-strip and --no-hiera-path-strip are mutually exclusive'
      end
      options[:to_hiera_path_strip] = :none
      options[:from_hiera_path_strip] = :none
    end
  end
end
