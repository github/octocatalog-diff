# frozen_string_literal: true

# Allow override of the branch that is cached. This defaults to 'origin/master'.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:master_cache_branch) do
  has_weight 160

  def parse(parser, options)
    parser.on('--master-cache-branch BRANCH', 'Branch to cache') do |x|
      options[:master_cache_branch] = x
    end
  end
end
