# frozen_string_literal: true

# Cache a bootstrapped checkout of 'master' and use that for time-saving when the SHA
# has not changed.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:cached_master_dir) do
  has_weight 160

  def parse(parser, options)
    parser.on('--cached-master-dir PATH', 'Cache bootstrapped origin/master at this path') do |path_in|
      path = File.absolute_path(path_in)
      unless Dir.exist?(path)
        begin
          Dir.mkdir path, 0o755
        rescue Errno::ENOENT => exc
          raise Errno::ENOENT, "Invalid cached master directory path: #{exc}"
        end
      end
      options[:cached_master_dir] = path
    end
  end
end
