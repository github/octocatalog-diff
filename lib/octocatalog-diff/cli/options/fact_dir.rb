# frozen_string_literal: true

# Allow a directory of per-node fact files to be provided, to avoid pulling facts from PuppetDB.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:fact_dir) do
  has_weight 149

  def parse(parser, options)
    OctocatalogDiff::Cli::Options.option_globally_or_per_branch(
      parser: parser,
      options: options,
      cli_name: 'fact-dir',
      option_name: 'fact_file_dir',
      desc: 'Fact directory',
      datatype: '',
      validator: lambda do |fact_dir|
        base_dir = options[:basedir]
        path = fact_dir.start_with?('/') ? File.expand_path(fact_dir) : File.expand_path(File.join(base_dir.to_s, fact_dir))
        raise Errno::ENOENT, "Fact directory #{path} does not exist" unless Dir.exist?(path)
      end,
      translator: lambda do |fact_dir|
        base_dir = options[:basedir]
        fact_dir.start_with?('/') ? File.expand_path(fact_dir) : File.expand_path(File.join(base_dir.to_s, fact_dir))
      end,
      post_process: lambda do |opts|
        if opts[:puppetdb_url]
          raise ArgumentError, '--fact-dir and --puppetdb-url are mutually exclusive'
        end
        if opts[:to_facts] || opts[:from_facts] || opts[:facts] || opts[:fact_file]
          raise ArgumentError, '--fact-dir and --fact-file are mutually exclusive'
        end
      end
    )
  end
end
