# frozen_string_literal: true

# Get the facts terminus. Generally this is 'yaml' and a fact file will be loaded from PuppetDB or
# elsewhere in the environment. However it can be set to 'facter' which will run facter on the host
# on which this is running.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:facts_terminus) do
  has_weight 310

  def parse(parser, options)
    termini = %w(yaml facter)
    parser.on('--facts-terminus STRING', "Facts terminus: one of #{termini.join(', ')}") do |x|
      raise ArgumentError, "Invalid facts terminus #{x}; supported: #{termini.join(', ')}" unless termini.include?(x)
      options[:facts_terminus] = x
    end
  end
end
