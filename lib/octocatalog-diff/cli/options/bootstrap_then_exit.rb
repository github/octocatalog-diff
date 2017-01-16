# frozen_string_literal: true

# Option to bootstrap directories and then exit
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:bootstrap_then_exit) do
  has_weight 70

  def parse(parser, options)
    parser.on('--bootstrap-then-exit', 'Bootstrap from-dir and/or to-dir and then exit') do
      options[:bootstrap_then_exit] = true
    end
  end
end
