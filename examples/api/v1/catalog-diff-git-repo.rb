#!/usr/bin/env ruby

# ------------------------------------------------------------------------------------
# This is a script that demonstrates the use of the OctocatalogDiff::API::V1.catalog_diff
# method to compare two catalogs.
#
# Run this with:
#   bundle exec examples/api/v1/catalog-diff-local-files.rb
#
# In this example, we'll compare two catalogs, based on branches from a git repository.
# ------------------------------------------------------------------------------------

# Once you have installed the gem, you want this:
#
# require 'octocatalog-diff'
#
# To make the script run correctly from within the `examples` directory, this locates
# the `octocatalog-diff` gem directly from this checkout.
require_relative '../../../lib/octocatalog-diff'

# Here are a few variables we'll use to compile this catalog. To ensure that this is a
# working script, it will use resources from the test fixtures. You will need adjust these
# to the actual values in your application.
FACT_FILE = File.expand_path('../../../spec/octocatalog-diff/fixtures/facts/facts.yaml', File.dirname(__FILE__))
NODE = 'rspec-node.github.net'.freeze
GIT_TARBALL = File.expand_path('../../../spec/octocatalog-diff/fixtures/git-repos/simple-repo.tar', File.dirname(__FILE__))
PUPPET_BINARY = File.expand_path('../../../script/puppet', File.dirname(__FILE__))

# Before we get started with the demo, I need to extract the tarball to create the git repo.
# You won't be doing this in your own script, so as the great and powerful Oz says, "pay no
# attention to the man behind the curtain."
require 'fileutils'
git_repo = Dir.mktmpdir
at_exit { FileUtils.remove_entry_secure git_repo if File.directory?(git_repo) }
system "tar -C '#{git_repo}' -xf '#{GIT_TARBALL}'"

# Just FYI, let's show you the checked out git repo.
puts 'Here is the directory containing the git repository.'
puts '$ ls -lR'
system "cd '#{git_repo}/git-repo' && ls -lR"

puts ''
puts '$ git branch'
system "cd '#{git_repo}/git-repo' && git branch"

# Set up a logger
strio = StringIO.new
logger = Logger.new strio

# To get the catalog differences, call the octocatalog-diff API.
puts ''
puts 'Please wait a few seconds for the catalogs to be compiled...'
result = OctocatalogDiff::API::V1.catalog_diff(
  basedir: File.join(git_repo, 'git-repo'),
  to_env: 'test-branch',
  from_env: 'master',
  fact_file: FACT_FILE,
  to_hiera_config: 'config/hiera.yaml', # Relative to the checkout, and only for the "to" catalog
  to_hiera_path: 'hieradata', # Relative to checkout, and only for the "to" catalog
  enc: 'config/enc.sh', # Relative to checkout
  bootstrap_script: 'script/bootstrap.sh', # Relative to checkout
  node: NODE,
  puppet_binary: PUPPET_BINARY,
  ignore: [
    { type: Regexp.new('\AClass\z'), title: Regexp.new('.*') } # Ignore all type=Class resources
  ],
  logger: logger
)

# Print the log
puts strio.string

# The `catalog-diff-local-files.rb` example explores the data structures of the
# return values. Here, simply report on the results.

puts ''
puts "The from-catalog has #{result.from.resources.size} resources"
# In the catalog, each resource is a hash, and the keys are strings not symbols.
result.from.resources.each do |resource|
  puts "  #{resource['type']}[#{resource['title']}]"
end

puts "The to-catalog has #{result.to.resources.size} resources"
result.to.resources.each do |resource|
  puts "  #{resource['type']}[#{resource['title']}]"
end

puts "There are #{result.diffs.size} differences"

result.diffs.each do |diff|
  if diff.addition?
    puts "Added a #{diff.type} resource called #{diff.title}!"
  elsif diff.removal?
    puts "Removed a #{diff.type} resource called #{diff.title}!"
  elsif diff.change?
    puts "Changed the #{diff.type} resource #{diff.title} attribute #{diff.structure.join('::')}"
    puts "   from #{diff.old_value.inspect} to #{diff.new_value.inspect}"
  else
    puts 'This is a bug - each entry is an addition, removal, or change.'
  end
end
