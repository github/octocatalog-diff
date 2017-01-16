# frozen_string_literal: true

# Allow the bootstrap environment to be set up via the command line.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:bootstrap_environment) do
  has_weight 50

  def parse(parser, options)
    descriptive_text = 'Bootstrap script environment variables in key=value format'
    parser.on('--bootstrap-environment "key1=val1,key2=val2,..."', Array, descriptive_text) do |res|
      options[:bootstrap_environment] ||= {}
      res.each do |item|
        raise ArgumentError, "Bootstrap environment #{item} must be in key=value format!" unless item =~ /=/
        key, val = item.split(/=/, 2)
        options[:bootstrap_environment][key] = Regexp.last_match(1) if val.strip =~ /^['"]?(.+?)['"]?$/
      end
    end
  end
end
