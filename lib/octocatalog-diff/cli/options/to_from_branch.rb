# frozen_string_literal: true

# Set the 'from' and 'to' branches, which is used to compile catalogs. A branch of '.' means to use
# the current contents of the base code directory without any git checkouts.
# @param parser [OptionParser object] The OptionParser argument
# @param options [Hash] Options hash being constructed; this is modified in this method.
OctocatalogDiff::Cli::Options::Option.newoption(:to_from_branch) do
  has_weight 20

  def parse(parser, options)
    parser.on('--from FROM_BRANCH', '-f', 'Branch you are coming from') do |env|
      options[:from_env] = env
    end
    parser.on('--to TO_BRANCH', '-t', 'Branch you are going to') do |env|
      options[:to_env] = env
    end
  end
end
