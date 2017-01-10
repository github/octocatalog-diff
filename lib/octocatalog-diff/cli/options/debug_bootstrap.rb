# frozen_string_literal: true

# Option to print debugging output for the bootstrap script in addition to the normal
# debugging output. Note that `--debug` must also be enabled for this option to have
# any effect.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:debug_bootstrap) do
  has_weight 49

  def parse(parser, options)
    parser.on('--debug-bootstrap', 'Print debugging output for bootstrap script') do
      options[:debug_bootstrap] = true
    end
  end
end
