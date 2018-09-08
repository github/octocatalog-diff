# frozen_string_literal: true

# Set hostname, which is used to look up facts in PuppetDB, and in the header of diff display.
# This option can recieve a single hostname, or a comma separated list of
# multiple hostnames, which are split into an Array. Multiple hostnames do not
# work with the `catalog-only` or `bootstrap-then-exit` options.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.

OctocatalogDiff::Cli::Options::Option.newoption(:hostname) do
  has_weight 1

  def parse(parser, options)
    parser.on(
      '--hostname HOSTNAME1[,HOSTNAME2[,...]]',
      '-n',
      'Use PuppetDB facts from last run of a hostname or a comma separated list of multiple hostnames'
    ) do |hostname|
      options[:node] = if hostname.include?(',')
        hostname.split(',')
      else
        hostname
      end
    end
  end
end
