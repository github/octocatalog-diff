# frozen_string_literal: true

# Specify a path to a file containing a PE RBAC token used to authenticate to the
# Puppetserver for a v4 catalog API call.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:puppet_master_token_file) do
  has_weight 300

  def parse(parser, options)
    OctocatalogDiff::Cli::Options.option_globally_or_per_branch(
      parser: parser,
      options: options,
      datatype: '',
      cli_name: 'puppet-master-token-file',
      option_name: 'puppet_master_token_file',
      desc: 'File containing PE RBAC token to authenticate to the Puppetserver API v4',
      translator: ->(x) { x.start_with?('/', '~') ? x : File.join(options[:basedir], x) },
      post_process: lambda do |opts|
        %w(to from).each do |prefix|
          fileopt = "#{prefix}_puppet_master_token_file".to_sym
          tokenopt = "#{prefix}_puppet_master_token".to_sym

          tokenfile = opts[fileopt]
          next if tokenfile.nil?

          raise(Errno::ENOENT, "Token file #{tokenfile} is not readable") unless File.readable?(tokenfile)

          token = File.read(tokenfile).strip
          opts[tokenopt] ||= token
        end
      end
    )
  end
end
