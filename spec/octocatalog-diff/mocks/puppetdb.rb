require 'json'

require_relative '../tests/spec_helper'

require OctocatalogDiff::Spec.require_path('/errors')
require OctocatalogDiff::Spec.require_path('/puppetdb')

module OctocatalogDiff
  module Mocks
    # This class mocks puppetdb for the purpose of spec testing. All it does
    # is return facts from the fact fixture directory in the format that PuppetDB
    # would return them.

    class PuppetDB
      # Constructor
      # @param overrides [Hash] Override fact result for node
      def initialize(overrides = {})
        @overrides = overrides
      end

      # This would ordinarily be a HTTP(S) call to puppetdb. Instead, look up something in the fixtures directory and return.
      # @param uri [String] URI
      # @return [Depends on what is requested]
      def get(uri)
        return facts(Regexp.last_match(1)) if uri =~ %r{^/pdb/query/v4/nodes/([^/]+)/facts$}
        return catalog(Regexp.last_match(1)) if uri =~ %r{^/pdb/query/v4/catalogs/(.+)$}
        return packages(Regexp.last_match(1)) if uri =~ %r{^/pdb/query/v4/package-inventory/(.+)$}
        raise ArgumentError, "PuppetDB URL not mocked: #{uri}"
      end

      # Mock facts from PuppetDB
      # @param hostname [String] Host name
      # @return [Array] A series of { 'name' => ..., 'value' => '...' } pairs
      def facts(hostname)
        return override_facts(hostname) if @overrides.key?(hostname)

        fixture_file = OctocatalogDiff::Spec.fixture_path(File.join('facts', "#{hostname}.yaml"))
        return [] unless File.file?(fixture_file)

        # Read the fact file to memory. Remove the first line (e.g. '!ruby/object:Puppet::Node::Facts')
        # so it doesn't try to load in all of puppet.
        fact_file = File.read(fixture_file).split(/\n/)
        fact_file[0] = '---'
        facts_in = YAML.load(fact_file.join("\n"))
        return [] unless facts_in.key?('values') && facts_in['values'].is_a?(Hash)

        # Convert the hash into an array of { 'name' => ..., 'value' => ... } pairs
        # and return it.
        facts_in['values'].keys.map { |k| { 'name' => k, 'value' => facts_in['values'][k] } }
      end

      # Override facts without actually performing queries
      # @param hostname [String] Host name
      # @return [Array] A series of { 'name' => ..., 'value' => '...' } pairs
      def override_facts(hostname)
        @overrides[hostname].keys.map { |k| { 'name' => k, 'value' => @overrides[hostname][k] } }
      end

      # Mock catalog from PuppetDB
      # @param hostname [String] Host name
      # @return [String] JSON catalog
      def catalog(hostname)
        fixture_file = OctocatalogDiff::Spec.fixture_path(File.join('catalogs', "#{hostname}.json"))
        raise OctocatalogDiff::Errors::PuppetDBNodeNotFoundError, '404 - Not Found' unless File.file?(fixture_file)
        JSON.parse(File.read(fixture_file))
      end

      # Mock packages from PuppetDB
      # @param hostname [String] Host name
      # @return [String] JSON catalog
      def packages(hostname)
        fixture_file = OctocatalogDiff::Spec.fixture_path(File.join('packages', "#{hostname}.json"))

        # If packages are requested from PuppetDB for an invalid node name, it will return 200 OK
        # with an empty list:
        if File.file?(fixture_file)
          JSON.parse(File.read(fixture_file))
        else
          []
        end
      end
    end
  end
end
