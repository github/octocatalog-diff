# frozen_string_literal: true

# Allow (or create) directories that are already bootstrapped. Handy to allow "bootstrap once, build many"
# to save time when diffing multiple catalogs on this system.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:bootstrapped_dirs) do
  has_weight 60

  def parse(parser, options)
    these_options = { 'from' => :bootstrapped_from_dir, 'to' => :bootstrapped_to_dir }
    these_options.each do |tag, hash_key|
      parser.on("--bootstrapped-#{tag}-dir DIRNAME", "Use a pre-bootstrapped '#{tag}' directory") do |dir|
        options[hash_key] = File.absolute_path(dir)
        Dir.mkdir options[hash_key], 0o700 unless Dir.exist?(options[hash_key])
        raise "Invalid bootstrapped-#{tag}-dir: does not exist" unless Dir.exist?(options[hash_key])
      end
    end
  end
end
