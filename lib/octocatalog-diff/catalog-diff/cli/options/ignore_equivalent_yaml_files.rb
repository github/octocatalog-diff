# frozen_string_literal: true

# Ignore difference between YAML files if they contain the same content differing only by whitespace.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::CatalogDiff::Cli::Options::Option.newoption(:ignore_equivalent_yaml_files) do
  has_weight 199

  def parse(parser, options)
    parser.on('--[no-]ignore-equivalent-yaml-files', 'Ignore YAML files differing only by whitespace') do |x|
      options[:ignore_equivalent_yaml_files] = x
    end
  end
end
