# frozen_string_literal: true

# Allow override of facts on the command line. Fact overrides can be supplied for the 'to' or 'from' catalog,
# or for both. There is some attempt to handle data types here (since all items on the command line are strings)
# by permitting a data type specification as well.
OctocatalogDiff::Cli::Options::Option.newoption(:fact_override) do
  has_weight 320

  def parse(parser, options)
    # Set 'fact_override_in' because more processing is needed, once the command line options
    # have been parsed, to make this into the final form 'fact_override'.
    # Avoid Array parsing here so JSON values with commas stay intact.
    parser.on('--fact-override STRING1[,STRING2[,...]]', 'Override fact globally') do |x|
      options[:to_fact_override_in] ||= []
      options[:from_fact_override_in] ||= []
      OctocatalogDiff::Cli::Options.split_override_list(x).each do |item|
        options[:to_fact_override_in] << item
        options[:from_fact_override_in] << item
      end
    end
    parser.on('--to-fact-override STRING1[,STRING2[,...]]', 'Override fact for the to branch') do |x|
      options[:to_fact_override_in] ||= []
      OctocatalogDiff::Cli::Options.split_override_list(x).each { |item| options[:to_fact_override_in] << item }
    end
    parser.on('--from-fact-override STRING1[,STRING2[,...]]', 'Override fact for the from branch') do |x|
      options[:from_fact_override_in] ||= []
      OctocatalogDiff::Cli::Options.split_override_list(x).each { |item| options[:from_fact_override_in] << item }
    end
  end
end
