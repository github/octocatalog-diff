# frozen_string_literal: true

# Enable future parser for both branches or for just one
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:parser) do
  has_weight 270

  def parse(parser, options)
    supported_parsers = %w(default future)
    parser_str = supported_parsers.join(', ')

    # --parser sets both parser-to and parser-from
    parser.on('--parser PARSER_NAME', "Specify parser (#{parser_str})") do |x|
      unless supported_parsers.include?(x)
        raise ArgumentError, "--parser must be one of: #{parser_str}"
      end
      unless options[:parser_from].nil? || options[:parser_from] == x.to_sym
        raise ArgumentError, '--parser conflicts with --parser-from'
      end
      unless options[:parser_to].nil? || options[:parser_to] == x.to_sym
        raise ArgumentError, '--parser conflicts with --parser-to'
      end
      options[:parser_from] = x.to_sym
      options[:parser_to] = x.to_sym
    end

    # --parser-from sets parser for the 'from' branch
    parser.on('--parser-from PARSER_NAME', "Specify parser (#{parser_str})") do |x|
      unless supported_parsers.include?(x)
        raise ArgumentError, "--parser-from must be one of: #{parser_str}"
      end
      unless options[:parser_from].nil? || options[:parser_from] == x.to_sym
        raise ArgumentError, '--parser incompatible with --parser-from'
      end
      options[:parser_from] = x.to_sym
    end

    # --parser-to sets parser for the 'to' branch
    parser.on('--parser-to PARSER_NAME', "Specify parser (#{parser_str})") do |x|
      unless supported_parsers.include?(x)
        raise ArgumentError, "--parser-to must be one of: #{parser_str}"
      end
      unless options[:parser_to].nil? || options[:parser_to] == x.to_sym
        raise ArgumentError, '--parser incompatible with --parser-to'
      end
      options[:parser_to] = x.to_sym
    end
  end
end
