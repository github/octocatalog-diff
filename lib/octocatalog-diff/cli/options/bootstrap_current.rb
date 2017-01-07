# frozen_string_literal: true

# Option to bootstrap the current directory (by default, the bootstrap script is NOT
# run when the catalog builds in the current directory).
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:bootstrap_current) do
  has_weight 48

  def parse(parser, options)
    parser.on('--bootstrap-current', 'Run bootstrap script for the current directory too') do
      options[:bootstrap_current] = true
    end
  end
end
