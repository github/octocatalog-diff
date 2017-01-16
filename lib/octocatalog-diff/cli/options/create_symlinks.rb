# frozen_string_literal: true

# Specify which directories from the base should be symlinked into the temporary compilation
# environment. This is useful only in conjunction with `--preserve-environments`.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:create_symlinks) do
  has_weight 503

  def parse(parser, options)
    OctocatalogDiff::Cli::Options.option_globally_or_per_branch(
      parser: parser,
      options: options,
      cli_name: 'create-symlinks',
      option_name: 'create_symlinks',
      desc: 'Symlinks to create',
      datatype: []
    )
  end
end
