# frozen_string_literal: true

# Allow catalogs to be saved to a file before they are diff'd.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:save_catalog) do
  has_weight 155

  def parse(parser, options)
    OctocatalogDiff::Cli::Options.option_globally_or_per_branch(
      parser: parser,
      options: options,
      cli_name: 'save-catalog',
      option_name: 'save_catalog',
      desc: 'Save intermediate catalogs into files',
      datatype: '',
      validator: lambda do |catalog_file|
        target_dir = File.dirname(catalog_file)
        unless File.directory?(target_dir)
          raise Errno::ENOENT, "Cannot save catalog to #{catalog_file} because parent directory does not exist"
        end
        if File.exist?(catalog_file) && !File.file?(catalog_file)
          raise ArgumentError, "Cannot overwrite #{catalog_file} which is not a file"
        end
        true
      end,
      post_process: lambda do |opts|
        if opts[:to_save_catalog] && opts[:to_save_catalog] == opts[:from_save_catalog]
          raise ArgumentError, 'Cannot use the same file for --to-save-catalog and --from-save-catalog'
        end
      end
    )
  end
end
