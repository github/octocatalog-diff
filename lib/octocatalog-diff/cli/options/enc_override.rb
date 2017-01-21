# frozen_string_literal: true

# Allow override of ENC parameters on the command line. ENC parameter overrides can be supplied for the 'to' or 'from' catalog,
# or for both. There is some attempt to handle data types here (since all items on the command line are strings)
# by permitting a data type specification as well. For parameters nested in hashes, use `::` as the delimiter.
OctocatalogDiff::Cli::Options::Option.newoption(:enc_override) do
  has_weight 322

  def parse(parser, options)
    # Set 'enc_override_in' because more processing is needed, once the command line options
    # have been parsed, to make this into the final form 'enc_override'.
    OctocatalogDiff::Cli::Options.option_globally_or_per_branch(
      parser: parser,
      options: options,
      cli_name: 'enc-override',
      option_name: 'enc_override_in',
      desc: 'Override parameter from ENC',
      datatype: []
    )
  end
end
