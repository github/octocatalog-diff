# frozen_string_literal: true

# By specifying a directory path here, you are explicitly giving permission to the program
# to delete it if it believes it needs to be created (e.g., if the SHA has changed of the
# cached directory).
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:safe_to_delete_cached_master_dir) do
  has_weight 160

  def parse(parser, options)
    parser.on('--safe-to-delete-cached-master-dir PATH', 'OK to delete cached master directory at this path') do |path_in|
      path = File.absolute_path(path_in)
      options[:safe_to_delete_cached_master_dir] = path
    end
  end
end
