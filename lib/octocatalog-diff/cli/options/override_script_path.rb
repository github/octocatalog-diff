# frozen_string_literal: true

# Provide an optional directory to override default built-in scripts such as git checkout
# and puppet version determination.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:override_script_path) do
  has_weight 385

  def parse(parser, options)
    parser.on('--override-script-path DIRNAME', 'Directory with scripts to override built-ins') do |dir|
      unless dir.start_with?('/')
        raise ArgumentError, 'Absolute path is required for --override-script-path'
      end

      unless File.directory?(dir)
        raise Errno::ENOENT, 'Invalid --override-script-path'
      end

      options[:override_script_path] = dir
    end
  end
end
