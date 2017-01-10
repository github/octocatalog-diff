# frozen_string_literal: true

require 'uri'

# Specify the URL to the Puppet Enterprise ENC API. By default, the node classifier service
# listens on port 4433 and all endpoints are relative to the /classifier-api/ path. That means
# the likely value for this option will be something like:
# https://your-pe-console-server:4433/classifier-api
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:pe_enc_url) do
  has_weight 350

  def parse(parser, options)
    parser.on('--pe-enc-url URL', 'Base URL for Puppet Enterprise ENC endpoint') do |url|
      obj = URI.parse(url)
      raise ArgumentError, 'PE ENC URL must be https' unless obj.is_a?(URI::HTTPS)
      options[:pe_enc_url] = url
    end
  end
end
