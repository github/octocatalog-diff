# frozen_string_literal: true

# Set storeconfigs (integration with PuppetDB for collected resources)
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:storeconfigs) do
  has_weight 220

  def parse(parser, options)
    parser.on('--[no-]storeconfigs', 'Enable integration with puppetdb for collected resources') do |x|
      options[:storeconfigs] = x
    end
  end
end
