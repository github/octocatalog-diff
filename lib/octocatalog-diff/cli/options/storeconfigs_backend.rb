# frozen_string_literal: true

# Set storeconfigs (integration with PuppetDB for collected resources)
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:storeconfigs) do
  has_weight 220

  def parse(parser, options)
    parser.on('--storeconfigs-backend TERMINUS', 'Set the terminus used for storeconfigs') do |x|
      options[:storeconfigs_backend] = x
    end
  end
end
