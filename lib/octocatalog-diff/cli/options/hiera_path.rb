# frozen_string_literal: true

# Specify the path to the Hiera data directory (relative to the top level Puppet checkout). For Puppet Enterprise and the
# Puppet control repo template, the value of this should be 'hieradata', which is the default.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:hiera_path) do
  has_weight 181

  def parse(parser, options)
    OctocatalogDiff::Cli::Options.option_globally_or_per_branch(
      parser: parser,
      options: options,
      cli_name: 'hiera-path',
      option_name: 'hiera_path',
      desc: 'Path to hiera data directory, relative to top directory of repository',
      validator: lambda do |path|
        if path.start_with?('/')
          raise ArgumentError, '--hiera-path PATH must be a relative path not an absolute path'
        end
      end,
      translator: lambda do |path|
        result = path.sub(%r{/+$}, '')
        raise ArgumentError, '--hiera-path must not be empty' if result.empty?
        result
      end,
      post_process: lambda do |opts|
        if opts.key?(:to_hiera_path_strip) && opts[:to_hiera_path_strip] != :none
          if opts.key?(:to_hiera_path) && opts[:to_hiera_path] != :none
            raise ArgumentError, '--hiera-path and --hiera-path-strip are mutually exclusive'
          end
        end
        if opts.key?(:from_hiera_path_strip) && opts[:from_hiera_path_strip] != :none
          if opts.key?(:from_hiera_path) && opts[:from_hiera_path] != :none
            raise ArgumentError, '--hiera-path and --hiera-path-strip are mutually exclusive'
          end
        end
        if opts[:to_hiera_path] == :none || opts[:from_hiera_path] == :none
          raise ArgumentError, '--hiera-path and --no-hiera-path are mutually exclusive'
        end
      end
    )

    parser.on('--no-hiera-path', 'Do not use any default hiera path settings') do
      if options[:to_hiera_path].is_a?(String) || options[:from_hiera_path].is_a?(String)
        raise ArgumentError, '--hiera-path and --no-hiera-path are mutually exclusive'
      end

      options[:from_hiera_path] = :none
      options[:to_hiera_path] = :none
    end
  end
end
