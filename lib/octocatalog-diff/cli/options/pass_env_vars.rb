# frozen_string_literal: true

# One or more environment variables that should be made available to the Puppet binary when parsing
# the catalog. For example, --pass-env-vars FOO,BAR will make the FOO and BAR environment variables
# available. Setting these variables is your responsibility outside of octocatalog-diff.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:pass_env_vars) do
  has_weight 600

  def parse(parser, options)
    descriptive_text = 'Environment variables to pass'
    parser.on('--pass-env-vars VAR1[,VAR2[,...]]', Array, descriptive_text) do |res|
      options[:pass_env_vars] ||= []
      res.each do |item|
        raise ArgumentError, "Environment variable #{item} must be in alphanumeric format!" unless item =~ /^\w+$/
        options[:pass_env_vars] << item
      end
    end
  end
end
