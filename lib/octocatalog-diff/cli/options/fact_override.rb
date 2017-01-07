# frozen_string_literal: true

# Allow override of facts on the command line. Fact overrides can be supplied for the 'to' or 'from' catalog,
# or for both. There is some attempt to handle data types here (since all items on the command line are strings)
# by permitting a data type specification as well.
OctocatalogDiff::Cli::Options::Option.newoption(:fact_override) do
  has_weight 320

  def parse(parser, options)
    # Set 'fact_override_in' because more processing is needed, once the command line options
    # have been parsed, to make this into the final form 'fact_override'.
    OctocatalogDiff::Cli::Options.option_globally_or_per_branch(
      parser: parser,
      options: options,
      cli_name: 'fact-override',
      option_name: 'fact_override_in',
      desc: 'Override fact',
      datatype: []
    )
  end
end
