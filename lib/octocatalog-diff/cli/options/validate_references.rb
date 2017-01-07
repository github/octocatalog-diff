# frozen_string_literal: true

# Confirm that each `before`, `require`, `subscribe`, and/or `notify` points to a valid
# resource in the catalog. This value should be specified as an array of which of these
# parameters are to be checked.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:validate_references) do
  has_weight 205

  def parse(parser, options)
    parser.on('--[no-]validate-references "before,require,subscribe,notify"', Array, 'References to validate') do |res|
      if res == false
        options[:validate_references] = []
      else
        options[:validate_references] ||= []
        res.each do |item|
          unless %w(before require subscribe notify).include?(item)
            raise ArgumentError, "Invalid reference validation #{item}"
          end

          options[:validate_references] << item
        end
      end
    end
  end
end
