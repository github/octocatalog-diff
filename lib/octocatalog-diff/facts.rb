# frozen_string_literal: true

require_relative 'errors'
require_relative 'facts/json'
require_relative 'facts/yaml'
require_relative 'facts/puppetdb'
require_relative 'external/pson/pure'

module OctocatalogDiff
  # Deal with facts in all forms, including:
  # - In existing YAML files
  # - In existing JSON files
  # - Retrieved dynamically from PuppetDB
  class Facts
    # Constructor
    # @param options [Hash] Initialization options, varies per backend
    def initialize(options = {}, facts = nil)
      @node = options.fetch(:node, '')
      @timestamp = false
      @options = options.dup
      if facts
        @facts = {}
        facts.each { |k, v| @facts[k] = v.dup }
      else
        case options[:backend]
        when :json
          @orig_facts = OctocatalogDiff::Facts::JSON.fact_retriever(options, @node)
        when :yaml
          @orig_facts = OctocatalogDiff::Facts::Yaml.fact_retriever(options, @node)
        when :puppetdb
          @orig_facts = OctocatalogDiff::Facts::PuppetDB.fact_retriever(options, @node)
        else
          raise ArgumentError, 'Invalid fact source backend'
        end
        @facts = {}
        @orig_facts.each { |k, v| @facts[k] = v.dup }
      end
    end

    def dup
      self.class.new(@options, @orig_facts)
    end

    # Facts - returned the 'cleansed' facts.
    # Clean up facts by setting 'name' to the node if given, and deleting _timestamp and expiration
    # which may cause Puppet catalog compilation to fail if the facts are old.
    # @param node [String] Node name to override returned facts
    # @return [Hash] Facts hash { 'name' => '...', 'values' => { ... } }
    def facts(node = @node, timestamp = false)
      raise "Expected @facts to be a hash but it is a #{@facts.class}" unless @facts.is_a?(Hash)
      raise "Expected @facts['values'] to be a hash but it is a #{@facts['values'].class}" unless @facts['values'].is_a?(Hash)
      f = @facts.dup
      f['name'] = node unless node.nil? || node.empty?
      f['values'].delete('_timestamp')
      f.delete('expiration')
      if timestamp
        f['timestamp'] = Time.now.to_s
        f['values']['timestamp'] = f['timestamp']
        f['expiration'] = (Time.now + (24 * 60 * 60)).to_s
      end
      f
    end

    # Facts - Fudge the timestamp to right now and add include it in the facts when returned
    # @return self
    def fudge_timestamp
      @timestamp = true
      self
    end

    # Facts - remove one or more facts from the list.
    # @param remove [String|Array<String>] Fact(s) to remove
    # @return self
    def without(remove)
      r = remove.is_a?(Array) ? remove : [remove]
      obj = dup
      r.each { |fact| obj.remove_fact_from_list(fact) }
      obj
    end

    # Facts - remove a fact from the list
    # @param remove [String] Fact to remove
    def remove_fact_from_list(remove)
      @facts['values'].delete(remove)
    end

    # Turn hash of facts into appropriate YAML for Puppet
    # @param node [String] Node name to override returned facts
    # @return [String] Puppet-compatible YAML facts
    def facts_to_yaml(node = @node)
      # Add the header that Puppet needs to treat this as facts. Save the results
      # as a string in the option.
      f = facts(node)
      fact_file = f.to_yaml.split(/\n/)
      fact_file[0] = '--- !ruby/object:Puppet::Node::Facts' if fact_file[0] =~ /^---/
      fact_file.join("\n")
    end

    # Turn hash of facts into appropriate YAML for Puppet
    # @param node [String] Node name to override returned facts
    # @return [String] Puppet-compatible YAML facts
    def to_pson
      PSON.generate(facts)
    end

    # Get the current value of a particular fact
    # @param key [String] Fact key to override
    # @return [?] Value for fact
    def fact(key)
      @facts['values'][key]
    end

    # Override a particular fact
    # @param key [String] Fact key to override
    # @param value [?] Value for fact
    def override(key, value)
      if value.nil?
        @facts['values'].delete(key)
      else
        @facts['values'][key] = value
      end
    end
  end
end
