# frozen_string_literal: true

# Path to external node classifier, relative to the base directory of the checkout.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:enc) do
  has_weight 240

  def parse(parser, options)
    parser.on('--no-enc', 'Disable ENC') do
      options[:no_enc] = true
      options[:enc] = nil
      options[:from_enc] = nil
      options[:to_enc] = nil
    end

    parser.on('--enc PATH', 'Path to ENC script, relative to checkout directory or absolute') do |x|
      unless options[:no_enc]
        proposed_enc_path = x.start_with?('/') ? x : File.join(options[:basedir], x)
        raise Errno::ENOENT, "Provided ENC (#{proposed_enc_path}) does not exist" unless File.file?(proposed_enc_path)
        options[:enc] = proposed_enc_path
      end
    end

    parser.on('--from-enc PATH', 'Path to ENC script (for the from catalog only)') do |x|
      options[:from_enc] = x unless options[:no_enc]
    end

    parser.on('--to-enc PATH', 'Path to ENC script (for the to catalog only)') do |x|
      options[:to_enc] = x unless options[:no_enc]
    end
  end
end
