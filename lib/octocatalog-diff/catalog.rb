# frozen_string_literal: true

require 'json'
require 'stringio'

require_relative 'catalog/computed'
require_relative 'catalog/json'
require_relative 'catalog/noop'
require_relative 'catalog/puppetdb'
require_relative 'catalog/puppetmaster'
require_relative 'catalog-util/fileresources'
require_relative 'errors'

module OctocatalogDiff
  # Basic methods for interacting with a catalog. Generation of the catalog is handled via one of the
  # supported backends listed above as 'require_relative'. Usually, the 'computed' backend
  # will build the catalog from the Puppet command.
  class Catalog
    attr_accessor :node
    attr_reader :built, :catalog, :catalog_json, :options

    # Constructor
    def initialize(options = {})
      unless options.is_a?(Hash)
        raise ArgumentError, "#{self.class}.initialize requires hash argument, not #{options.class}"
      end
      @options = options

      # Basic settings
      @node = options[:node]
      @error_message = nil
      @catalog = nil
      @catalog_json = nil
      @retries = nil

      # The compilation directory can be overridden, e.g. when testing
      @override_compilation_dir = options[:compilation_dir]

      # Keep track of whether references have been validated yet. Allow this to be fudged for when we do
      # not desire reference validation to happen (e.g., for the "from" catalog that is otherwise valid).
      @references_validated = options[:references_validated] || false

      # Keep track of whether file resources have been converted.
      @file_resources_converted = false

      # Keep track of whether it's built yet
      @built = false
    end

    # Guess the backend from the input and return the appropriate catalog object.
    # @param :backend [Symbol] If set, this will force a backend
    # @param :json [String] JSON catalog content (will avoid running Puppet to compile catalog)
    # @param :puppetdb [Object] If set, pull the catalog from PuppetDB rather than building
    # @param :node [String] Name of node whose catalog is being built
    # @param :fact_file [String] OPTIONAL: Path to fact file (if not provided, look up in PuppetDB)
    # @param :hiera_config [String] OPTIONAL: Path to hiera config file (munge temp. copy if not provided)
    # @param :basedir [String] OPTIONAL: Base directory for catalog (default base directory of this checkout)
    # @param :pass_env_vars [Array<String>] OPTIONAL: Additional environment vars to pass
    # @param :convert_file_resources [Boolean] OPTIONAL: Convert file resource source to content
    # @param :storeconfigs [Boolean] OPTIONAL: Pass the '-s' flag, for puppetdb (storeconfigs) integration
    # @return [OctocatalogDiff::Catalog::<?>] Catalog object from guessed backend
    def self.create(options = {})
      # Hard-coded backend
      if options[:backend]
        return OctocatalogDiff::Catalog::JSON.new(options) if options[:backend] == :json
        return OctocatalogDiff::Catalog::PuppetDB.new(options) if options[:backend] == :puppetdb
        return OctocatalogDiff::Catalog::PuppetMaster.new(options) if options[:backend] == :puppetmaster
        return OctocatalogDiff::Catalog::Computed.new(options) if options[:backend] == :computed
        return OctocatalogDiff::Catalog::Noop.new(options) if options[:backend] == :noop
        raise ArgumentError, "Unknown backend :#{options[:backend]}"
      end

      # Determine backend based on arguments
      return OctocatalogDiff::Catalog::JSON.new(options) if options[:json]
      return OctocatalogDiff::Catalog::PuppetDB.new(options) if options[:puppetdb]
      return OctocatalogDiff::Catalog::PuppetMaster.new(options) if options[:puppet_master]

      # Default is to build catalog ourselves
      OctocatalogDiff::Catalog::Computed.new(options)
    end

    # Build catalog - this method needs to be called to build the catalog. It is separate due to
    # the serialization of the logger object -- the parallel gem cannot serialize/deserialize a logger
    # object so it cannot be part of any object that is passed around.
    # @param logger [Logger] Logger object, initialized to a default throwaway value
    def build(logger = Logger.new(StringIO.new))
      # If already built, don't build again
      return if @built
      @built = true

      # The resource hash is computed the first time it's needed. For now initialize it as nil.
      @resource_hash = nil

      # Invoke the backend's build method, if there is one. There's a stub below in case there's not.
      logger.debug "Calling build for object #{self.class}"
      build_catalog(logger)

      # Perform post-generation processing of the catalog
      return unless valid?

      validate_references
      return unless valid?

      convert_file_resources if @options[:compare_file_text]

      true
    end

    # Stub method if the backend does not contain a build method.
    def build_catalog(_logger)
    end

    # Compilation environment
    # @return [String] Compilation environment (if set), else 'production' by default
    def environment
      @environment ||= 'production'
    end

    # For logging we may wish to know the backend being used
    # @return [String] Class of backend used
    def builder
      self.class.to_s
    end

    # Set the catalog JSON
    # @param str [String] Catalog JSON
    def catalog_json=(str)
      @catalog_json = str
      @resource_hash = nil
    end

    # This retrieves the compilation directory from the catalog, or otherwise the passed-in directory.
    # @return [String] Compilation directory
    def compilation_dir
      @override_compilation_dir || @options[:basedir]
    end

    # The compilation directory can be overridden, e.g. during testing.
    # @param dir [String] Compilation directory
    def compilation_dir=(dir)
      @override_compilation_dir = dir
    end

    # Stub method for "convert_file_resources" -- returns false because if the underlying class does
    # not implement this method, it's not supported.
    def convert_file_resources(_dry_run = false)
      false
    end

    # Retrieve the error message.
    # @return [String] Error message (maximum 20,000 characters) - nil if no error.
    def error_message
      build
      return nil if @error_message.nil? || !@error_message.is_a?(String)
      @error_message[0, 20_000]
    end

    # Allow setting the error message. If the error message is set to a string, the catalog
    # and catalog JSON are set to nil.
    # @param error [String] Error message
    def error_message=(error)
      raise ArgumentError, 'Error message must be a string' unless error.is_a?(String)
      @error_message = error
      @catalog = nil
      @catalog_json = nil
      @resource_hash = nil
    end

    # Stub method to return the puppet version if the back end doesn't support this.
    # @return [String] Puppet version
    def puppet_version
      build
      @options[:puppet_version]
    end

    # This allows retrieving a resource by type and title. This is intended for use when a O(1) lookup is required.
    # @param :type [String] Type of resource
    # @param :title [String] Title of resource
    # @return [Hash] Resource item
    def resource(opts = {})
      raise ArgumentError, ':type and :title are required' unless opts[:type] && opts[:title]
      build
      build_resource_hash if @resource_hash.nil?
      return nil unless @resource_hash[opts[:type]].is_a?(Hash)
      @resource_hash[opts[:type]][opts[:title]]
    end

    # This is a compatibility layer for the resources, which are in a different place in Puppet 3.x and Puppet 4.x
    # @return [Array] Resource array
    def resources
      build
      raise OctocatalogDiff::Errors::CatalogError, 'Catalog does not appear to have been built' if !valid? && error_message.nil?
      raise OctocatalogDiff::Errors::CatalogError, error_message unless valid?
      return @catalog['data']['resources'] if @catalog['data'].is_a?(Hash) && @catalog['data']['resources'].is_a?(Array)
      return @catalog['resources'] if @catalog['resources'].is_a?(Array)
      # This is a bug condition
      # :nocov:
      raise "BUG: catalog has no data::resources or ::resources array. Please report this. #{@catalog.inspect}"
      # :nocov:
    end

    # Stub method of the the number of retries necessary to compile the catalog. If the underlying catalog
    # generation backend does not support retries, nil is returned.
    # @return [Integer] Retry count
    def retries
      nil
    end

    # Determine if the catalog build was successful.
    # @return [Boolean] Whether the catalog is valid
    def valid?
      build
      !@catalog.nil?
    end

    # Determine if all of the (before, notify, require, subscribe) targets are actually in the catalog.
    # Raise a OctocatalogDiff::Errors::ReferenceValidationError for any found to be missing.
    # Uses @options[:validate_references] to influence which references are checked.
    def validate_references
      # If we've already done the validation, don't do it again
      return if @references_validated
      @references_validated = true

      # Skip out early if no reference validation has been requested.
      unless @options[:validate_references].is_a?(Array) && @options[:validate_references].any?
        return
      end

      # Puppet 5 has reference validation built-in and enabled, so there won't even be a valid catalog if
      # there were invalid references. It's pointless to perform validation of our own.
      return if puppet_version && puppet_version >= '5.0.0'

      # Iterate over all the resources and check each one that has one of the attributes being checked.
      # Keep track of all references that are missing for ultimate inclusion in the error message.
      missing = []
      resources.each do |x|
        @options[:validate_references].each do |r|
          next unless x.key?('parameters')
          next unless x['parameters'].key?(r)
          missing_resources = resources_missing_from_catalog(x['parameters'][r])
          next unless missing_resources.any?
          missing.concat missing_resources.map { |missing_target| { source: x, target_type: r, target_value: missing_target } }
        end
      end
      return if missing.empty?

      # At this point there is at least one broken/missing reference. Format an error message and raise.
      errors = format_missing_references(missing)
      plural = errors =~ /;/ ? 's' : ''
      self.error_message = "Catalog has broken reference#{plural}: #{errors}"
    end

    private

    # Private method: Format the name of the source file and line number, based on compilation directory and
    # other settings. This is used by format_missing_references.
    # @param source_file [String] Raw source file name from catalog
    # @param line_number [Fixnum] Line number from catalog
    # @return [String] Formatted source file
    def format_source_file_line(source_file, line_number)
      return '' if source_file.nil? || source_file.empty?
      filename = if compilation_dir && source_file.start_with?(compilation_dir)
        stripped_file = source_file[compilation_dir.length..-1]
        stripped_file.start_with?('/') ? stripped_file[1..-1] : stripped_file
      else
        source_file
      end
      "(#{filename.sub(%r{^environments/production/}, '')}:#{line_number})"
    end

    # Private method: Format the missing references into human-readable text
    # Error message will look like this:
    # ---
    # Catalog has broken references: exec[subscribe caller 1](file:line) -> subscribe[Exec[subscribe target]];
    # exec[subscribe caller 2](file:line) -> subscribe[Exec[subscribe target]]; exec[subscribe caller 2](file:line) ->
    # subscribe[Exec[subscribe target 2]]
    # ---
    # @param missing [Array] Array of missing references
    # @return [String] Formatted references
    def format_missing_references(missing)
      unless missing.is_a?(Array) && missing.any?
        raise ArgumentError, 'format_missing_references() requires a non-empty array as input'
      end

      formatted_references = missing.map do |obj|
        # obj[:target_value] can be a string or an array. If it's an array, create a
        # separate error message per element of that array. This allows the total number
        # of errors to be correct.
        src_ref = "#{obj[:source]['type'].downcase}[#{obj[:source]['title']}]"
        src_file = format_source_file_line(obj[:source]['file'], obj[:source]['line'])
        target_val = obj[:target_value].is_a?(Array) ? obj[:target_value] : [obj[:target_value]]
        target_val.map { |tv| "#{src_ref}#{src_file} -> #{obj[:target_type].downcase}[#{tv}]" }
      end.flatten
      formatted_references.join('; ')
    end

    # Private method: Given a list of resources to check, return the references from
    # that list that are missing from the catalog. (An empty array returned would indicate
    # all references are present in the catalog.)
    # @param resources_to_check [String / Array] Resources to check
    # @return [Array] References that are missing from catalog
    def resources_missing_from_catalog(resources_to_check)
      [resources_to_check].flatten.select do |res|
        unless res =~ /\A([\w:]+)\[(.+)\]\z/
          raise ArgumentError, "Resource #{res} is not in the expected format"
        end

        type = Regexp.last_match(1)
        title = normalized_title(Regexp.last_match(2), type)
        resource(type: type, title: title).nil?
      end
    end

    # Private method: Given a title string, normalize it according to the rules
    # used by puppet 4.10.x for file resource title normalization:
    # https://github.com/puppetlabs/puppet/blob/4.10.x/lib/puppet/type/file.rb#L42
    def normalized_title(title_string, type)
      return title_string if type != 'File'

      matches = title_string.match(%r{^(?<normalized_path>/|.+:/|.*[^/])/*\Z}m)
      matches[:normalized_path] || title_string
    end

    # Private method: Build the resource hash to be used used for O(1) lookups by type and title.
    # This method is called the first time the resource hash is accessed.
    def build_resource_hash
      @resource_hash = {}
      resources.each do |resource|
        @resource_hash[resource['type']] ||= {}

        title = normalized_title(resource['title'], resource['type'])
        @resource_hash[resource['type']][title] = resource

        if resource.key?('parameters')
          @resource_hash[resource['type']][resource['parameters']['alias']] = resource if resource['parameters'].key?('alias')
          @resource_hash[resource['type']][resource['parameters']['name']] = resource if resource['parameters'].key?('name')
        end
      end
    end
  end
end
