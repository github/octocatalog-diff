# frozen_string_literal: true

# Provide ability to set custom header or to display no header at all
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:header) do
  has_weight 260

  def parse(parser, options)
    parser.on('--no-header', 'Do not print a header') do
      raise ArgumentError, '--no-header incompatible with --default-header' if options[:header] == :default
      raise ArgumentError, '--no-header incompatible with --header' unless options[:header].nil?
      options[:no_header] = true
    end
    parser.on('--default-header', 'Print default header with output') do
      raise ArgumentError, '--default-header incompatible with --header' unless options[:header].nil?
      raise ArgumentError, '--default-header incompatible with --no-header' unless options[:no_header].nil?
      options[:header] = :default
    end
    parser.on('--header STRING', 'Specify header for output') do |x|
      raise ArgumentError, '--header incompatible with --default-header' if options[:header] == :default
      raise ArgumentError, '--header incompatible with --no-header' unless options[:no_header].nil?
      options[:header] = x
    end
  end
end
