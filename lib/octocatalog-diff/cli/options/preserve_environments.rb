# frozen_string_literal: true

# Preserve the `environments` directory from the repository when compiling the catalog. Likely
# requires some combination of `--to-environment`, `--from-environment`, and/or `--create-symlinks`
# to work correctly.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:preserve_environments) do
  has_weight 501

  def parse(parser, options)
    parser.on('--[no-]preserve-environments', 'Enable or disable environment preservation') do |x|
      options[:preserve_environments] = x
    end
  end
end
