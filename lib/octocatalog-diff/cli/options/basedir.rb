# frozen_string_literal: true

# Option to set the base checkout directory of puppet repository
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:basedir) do
  has_weight 10

  def parse(parser, options)
    parser.on('--basedir DIRNAME', 'Use an alternate base directory (git checkout of puppet repository)') do |dir|
      path = File.absolute_path(dir)
      raise Errno::ENOENT, 'Invalid basedir provided' unless Dir.exist?(path)
      options[:basedir] = path
    end
  end
end
