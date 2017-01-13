#!/usr/bin/env ruby

# ------------------------------------------------------------------------------------
# This is a script that demonstrates the use of the OctocatalogDiff::API::V1.catalog_diff
# method to compare two catalogs.
#
# Run this with:
#   bundle exec examples/api/v1/catalog-diff-local-files.rb
#
# In this example, we'll compare two catalogs.
# - The "from" catalog will be a catalog that has already been compiled, and exists as a JSON file.
#   We will use one of the JSON files from the spec fixtures.
# - The "to" catalog will be compiled using Puppet from one of the spec fixtures.
#
# This example will NOT show integration with a git repository. The `catalog-diff-git-repo.rb` file in
# this directory shows off those features.
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
HIERA_CONFIG = File.expand_path('../../../spec/octocatalog-diff/fixtures/repos/default/config/hiera.yaml', File.dirname(__FILE__))
NODE = 'rspec-node.github.net'.freeze
FROM_CATALOG = File.expand_path('../../../spec/octocatalog-diff/fixtures/catalogs/ignore-tags-new.json', File.dirname(__FILE__))
PUPPET_REPO = File.expand_path('../../../spec/octocatalog-diff/fixtures/repos/ignore-tags-old', File.dirname(__FILE__))
PUPPET_BINARY = File.expand_path('../../../script/puppet', File.dirname(__FILE__))

# To get the catalog differences, call the octocatalog-diff API.
puts 'Please wait a few seconds for the catalogs to be compiled...'
result = OctocatalogDiff::API::V1.catalog_diff(
  bootstrapped_to_dir: PUPPET_REPO,
  fact_file: FACT_FILE,
  from_catalog: FROM_CATALOG,
  hiera_config: HIERA_CONFIG,
  hiera_path: 'hieradata',
  node: NODE,
  puppet_binary: PUPPET_BINARY
)

# We should get back a structure with 3 keys: `:diffs` will be an array of differences; `:from` will be the "from"
# catalog (which in this case is taken directly from the JSON file), and `:to` will be the "to" catalog (which
# in this case was compiled). We use 'Openstruct' so that you can treat it as a hash, or as an object with methods.
puts "Object returned from OctocatalogDiff::API::V1.catalog_diff is: #{result.class}"

# Let's see what kind of objects we have. First, treating the result as a hash:
puts "The keys are: #{result.to_h.keys.join(', ')}"
[:diffs, :from, :to].each do |key|
  puts "result[:#{key}] is a(n) #{result[key].class}"
end

# We can also use these as methods.
[:diffs, :from, :to].each do |key|
  puts "result.#{key} is a(n) #{result.send(key).class}"
end

# Let's inspect the :diffs array a bit.
puts "The first element of result.diffs is a(n) #{result.send(:diffs).first.class}"
puts "There are #{result[:diffs].size} diffs reported here"

# Let's print the first diff in JSON format
d = result.diffs.first
puts '--------------------------------------'
puts 'The first diff is:'
puts d.inspect

# Internally, the structure of the diff is an array
puts '--------------------------------------'
puts 'The raw object format of that diff is:'
puts d.raw.inspect
