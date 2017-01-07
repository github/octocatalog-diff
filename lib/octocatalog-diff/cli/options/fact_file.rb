# frozen_string_literal: true

# Allow an existing fact file to be provided, to avoid pulling facts from PuppetDB.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:fact_file) do
  has_weight 150

  def parse(parser, options)
    parser.on('--fact-file FILENAME', 'Fact file to use instead of node lookup') do |fact_file|
      raise Errno::ENOENT, 'Invalid fact file provided' unless File.file?(fact_file)
      facts = nil
      local_opts = { fact_file_string: File.read(fact_file) }
      if fact_file =~ /\.ya?ml$/
        facts = OctocatalogDiff::Facts.new(local_opts.merge(backend: :yaml))
      elsif fact_file =~ /\.json$/
        facts = OctocatalogDiff::Facts.new(local_opts.merge(backend: :json))
      else
        raise ArgumentError, 'I do not know how to parse the provided fact file. Needs .yaml or .json extension.'
      end
      options[:facts] = facts
      options[:node] ||= facts.facts['name']
    end
  end
end
