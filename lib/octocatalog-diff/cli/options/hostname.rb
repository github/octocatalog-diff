# frozen_string_literal: true

# Set hostname, which is used to look up facts in PuppetDB, and in the header of diff display.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.

OctocatalogDiff::Cli::Options::Option.newoption(:hostname) do
  has_weight 1

  def parse(parser, options)
    parser.on('--hostname HOSTNAME', '-n', 'Use PuppetDB facts from last run of hostname') do |hostname|
      options[:node] = hostname
    end
  end
end
