# frozen_string_literal: true

require 'json'

# If pre-compiled catalogs are available, these can be used to short-circuit the build process.
# These files must exist and be in Puppet catalog format.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:existing_catalogs) do
  has_weight 30

  def parse(parser, options)
    these_options = { 'from' => :from_catalog, 'to' => :to_catalog }
    these_options.each do |tag, hash_key|
      parser.on("--#{tag}-catalog FILENAME", "Use a pre-compiled catalog '#{tag}'") do |catalog_file|
        path = File.absolute_path(catalog_file)
        raise Errno::ENOENT, "Invalid '#{hash_key} catalog' file provided" unless File.file?(path)
        options[hash_key] = path
        if options[:node].nil?
          x = JSON.parse(File.read(path))
          options[:node] ||= x['data']['name'] if x['data'].is_a?(Hash)
          options[:node] ||= x['name'] if x['name'].is_a?(String)
        end
      end
    end
  end
end
