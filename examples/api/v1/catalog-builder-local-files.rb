#!/usr/bin/env ruby

# ------------------------------------------------------------------------------------
# This is a script that demonstrates the use of the OctocatalogDiff::API::V1.catalog
# method to build a catalog.
#
# Run this with:
#   bundle exec examples/api/v1/catalog-builder-local-files.rb
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
PUPPET_REPO = File.expand_path('../../../spec/octocatalog-diff/fixtures/repos/default', File.dirname(__FILE__))
PUPPET_BINARY = File.expand_path('../../../script/puppet', File.dirname(__FILE__))

# To compile this catalog, call the octocatalog-diff API.
catalog = OctocatalogDiff::API::V1.catalog(
  bootstrapped_to_dir: PUPPET_REPO,
  fact_file: FACT_FILE,
  hiera_config: HIERA_CONFIG,
  hiera_path: 'hieradata',
  node: NODE,
  puppet_binary: PUPPET_BINARY
)

# Let's see what kind of an object we got...
# #=> OctocatalogDiff::API::V1::Catalog
puts "Object returned from OctocatalogDiff::API::V1.catalog is: #{catalog.class}"

# If it's not valid, the error message will be available.
unless catalog.valid?
  puts 'The catalog is not valid.'
  puts catalog.error_message
  exit 1
end

# If it is valid, many other methods may be of interest.
puts 'The catalog is valid.'

# We can determine which backend was used to build it. With the arguments in this example,
# the catalog was computed.
# #=> OctocatalogDiff::Catalog::Computed
puts "The catalog was built using #{catalog.builder}"

# We can determine which directory was used as the temporary compilation directory.
# This is only defined for the Computed backend.
puts "Puppet was run in #{catalog.compilation_dir}"

# We can report on which version of Puppet was run. This is only defined for the
# Computed backend.
puts "The version of Puppet used was #{catalog.puppet_version}"

# We can get all resources in the catalog via the .resources method, which returns
# an Array<Hash>. The Hash comes directly from the catalog structure.
puts "There is/are #{catalog.resources.count} resource(s) in this catalog"
catalog.resources.each do |resource|
  puts "- #{resource['type']} - #{resource['title']}"
end

# You can also locate a resource by its type and title. We'll choose an element at
# random from the array. We will then locate it via the `.resource` method.
selected_resource = catalog.resources.sample
puts "Randomly selected type=#{selected_resource['type']} title=#{selected_resource['title']}"

param = { type: selected_resource['type'], title: selected_resource['title'] }
looked_up_resource = catalog.resource(param)
puts "Looked up using catalog.resource: type=#{looked_up_resource['type']}, title=#{looked_up_resource['title']}"

if selected_resource == looked_up_resource
  puts 'The resources are equal!'
else
  # If this happens, it's a bug - please report it to us!
  puts 'The resources do not match!'
end

# If we want the JSON representation of the catalog, we can get that too. You'd
# normally want to write this out to a file. We'll just print the first 80 characters.
json_text = catalog.to_json
puts "The JSON representation of the catalog is #{json_text.length} characters long"
puts json_text[0..80]
