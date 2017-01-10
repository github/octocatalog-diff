# frozen_string_literal: true

# Allow specification of a bootstrap script. This runs after checking out the directory, and before running
# puppet there. Good for running librarian to install modules, and anything else site-specific that needs
# to be done.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:bootstrap_script) do
  has_weight 40

  def parse(parser, options)
    parser.on('--bootstrap-script FILENAME', 'Bootstrap script relative to checkout directory') do |file|
      options[:bootstrap_script] = file
    end
  end
end
