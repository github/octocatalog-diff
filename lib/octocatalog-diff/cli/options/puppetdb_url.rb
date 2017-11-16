# frozen_string_literal: true

require 'uri'

# Specify the base URL for PuppetDB. This will generally look like https://puppetdb.yourdomain.com:8081
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:puppetdb_url) do
  has_weight 310
  order_within_weight 1

  def parse(parser, options)
    parser.on('--puppetdb-url URL', 'PuppetDB base URL') do |url|
      # Test the format of the incoming URL. Only HTTPS should really be used, but we will
      # support HTTP begrudgingly as well.
      obj = URI.parse(url)
      raise ArgumentError, 'PuppetDB URL must be http or https' unless obj.is_a?(URI::HTTPS) || obj.is_a?(URI::HTTP)
      options[:puppetdb_url] = url
    end
  end
end
