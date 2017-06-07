# frozen_string_literal: true

# Allow an existing fact file to be provided, to avoid pulling facts from PuppetDB.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:fact_file) do
  has_weight 150

  def parse(parser, options)
    OctocatalogDiff::Cli::Options.option_globally_or_per_branch(
      parser: parser,
      options: options,
      cli_name: 'fact-file',
      option_name: 'facts',
      desc: 'Override fact',
      datatype: '',
      validator: ->(fact_file) { File.file?(fact_file) && (fact_file =~ /\.ya?ml$/ || fact_file =~ /\.json$/) },
      translator: lambda do |fact_file|
        local_opts = { fact_file_string: File.read(fact_file) }
        if fact_file =~ /\.ya?ml$/
          OctocatalogDiff::Facts.new(local_opts.merge(backend: :yaml))
        elsif fact_file =~ /\.json$/
          OctocatalogDiff::Facts.new(local_opts.merge(backend: :json))
        else
          # :nocov:
          # Believed to be a bug condition since the validator should kick this out before it ever gets here.
          raise ArgumentError, 'I do not know how to parse the provided fact file. Needs .yaml or .json extension.'
          # :nocov:
        end
      end,
      post_process: lambda do |opts|
        unless options[:node]
          %w[to_facts from_facts facts].each do |opt|
            next unless opts[opt.to_sym] && opts[opt.to_sym].node
            opts[:node] = opts[opt.to_sym].node
            break
          end
        end
      end
    )
  end
end
