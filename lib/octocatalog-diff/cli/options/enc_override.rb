# frozen_string_literal: true

# Allow override of ENC parameters on the command line. ENC parameter overrides can be supplied for the 'to' or 'from' catalog,
# or for both. There is some attempt to handle data types here (since all items on the command line are strings)
# by permitting a data type specification as well. For parameters nested in hashes, use `::` as the delimiter.
OctocatalogDiff::Cli::Options::Option.newoption(:enc_override) do
  has_weight 322

  def parse(parser, options)
    parser.on('--enc-override STRING1[,STRING2[,...]]', 'Override parameter from ENC globally') do |x|
      options[:to_enc_override_in] ||= []
      options[:from_enc_override_in] ||= []
      OctocatalogDiff::Cli::Options.split_override_list(x).each do |item|
        options[:to_enc_override_in] << item
        options[:from_enc_override_in] << item
      end
    end
    parser.on('--to-enc-override STRING1[,STRING2[,...]]', 'Override parameter from ENC for the to branch') do |x|
      options[:to_enc_override_in] ||= []
      OctocatalogDiff::Cli::Options.split_override_list(x).each { |item| options[:to_enc_override_in] << item }
    end
    parser.on('--from-enc-override STRING1[,STRING2[,...]]', 'Override parameter from ENC for the from branch') do |x|
      options[:from_enc_override_in] ||= []
      OctocatalogDiff::Cli::Options.split_override_list(x).each { |item| options[:from_enc_override_in] << item }
    end
  end
end
