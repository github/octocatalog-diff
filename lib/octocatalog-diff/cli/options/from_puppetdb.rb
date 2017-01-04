# frozen_string_literal: true

# Set --from-puppetdb to pull most recent catalog from PuppetDB instead of compiling
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:from_puppetdb) do
  has_weight 300

  def parse(parser, options)
    desc = 'Pull "from" catalog from PuppetDB instead of compiling'
    parser.on('--[no-]from-puppetdb', desc) do |x|
      options[:from_puppetdb] = x
    end
  end
end
