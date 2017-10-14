# frozen_string_literal: true

require_relative 'api/v1'
require_relative 'catalog-util/cached_master_directory'
require_relative 'cli/diffs'
require_relative 'cli/options'
require_relative 'cli/printer'
require_relative 'errors'
require_relative 'util/catalogs'
require_relative 'util/util'
require_relative 'version'

require 'logger'
require 'socket'

module OctocatalogDiff
  # This is the CLI for catalog-diff. It's responsible for parsing the command line
  # arguments and then handing off to appropriate methods to perform the catalog-diff.
  class Cli
    # Version number
    VERSION = OctocatalogDiff::Version::VERSION

    # Exit codes
    EXITCODE_SUCCESS_NO_DIFFS = 0
    EXITCODE_FAILURE = 1
    EXITCODE_SUCCESS_WITH_DIFFS = 2

    # The default type+title+attribute to ignore in catalog-diff.
    DEFAULT_IGNORES = [
      { type: 'Class' } # Don't care about classes themselves, only what they actually do!
    ].freeze

    # The default options.
    DEFAULT_OPTIONS = {
      from_env: 'origin/master',
      to_env: '.',
      colors: true,
      debug: false,
      quiet: false,
      format: :color_text,
      display_source_file_line: false,
      compare_file_text: true,
      display_datatype_changes: true,
      parallel: true,
      suppress_absent_file_details: true,
      hiera_path: 'hieradata'
    }.freeze

    # This method is the one to call externally. It is possible to specify alternate
    # command line arguments, for testing.
    # @param argv [Array] Use specified arguments (defaults to ARGV)
    # @param logger [Logger] Logger object
    # @param opts [Hash] Additional options
    # @return [Integer] Exit code: 0=no diffs, 1=something went wrong, 2=worked but there are diffs
    def self.cli(argv = ARGV, logger = Logger.new(STDERR), opts = {})
      # Save a copy of argv to print out later in debugging
      argv_save = OctocatalogDiff::Util::Util.deep_dup(argv)

      # Are there additional ARGV to munge, e.g. that have been supplied in the options from a
      # configuration file?
      if opts.key?(:additional_argv)
        raise ArgumentError, ':additional_argv must be array!' unless opts[:additional_argv].is_a?(Array)
        argv.concat opts[:additional_argv]
      end

      # Parse command line
      options = parse_opts(argv)

      # Additional options from hard-coded specified options. These are only processed if
      # there are not already values defined from command line options.
      # Note: do NOT use 'options[k] ||= v' here because if the value of options[k] is boolean(false)
      # it will then be overridden. Whereas the intent is to define values only for those keys that don't exist.
      opts.each { |k, v| options[k] = v unless options.key?(k) }
      veto_options = %w(enc header include_tags)
      veto_options.each { |x| options.delete(x.to_sym) if options["no_#{x}".to_sym] }
      if options[:no_hiera_config]
        vetoes = %w[hiera_config to_hiera_config from_hiera_config]
        vetoes.each do |key|
          options.delete(key.to_sym)
        end
      end
      options[:ignore].concat opts.fetch(:additional_ignores, [])

      # Incorporate default options where needed.
      # Note: do NOT use 'options[k] ||= v' here because if the value of options[k] is boolean(false)
      # it will then be overridden. Whereas the intent is to define values only for those keys that don't exist.
      DEFAULT_OPTIONS.each { |k, v| options[k] = v unless options.key?(k) }
      veto_with_none_options = %w(hiera_path hiera_path_strip)
      veto_with_none_options.each { |x| options.delete(x.to_sym) if options[x.to_sym] == :none }

      # Fact and ENC overrides come in here - 'options' is modified
      setup_fact_overrides(options)
      setup_enc_overrides(options)

      # Configure the logger and logger.debug initial information
      # 'logger' is modified and used
      setup_logger(logger, options, argv_save)

      # --catalog-only is a special case that compiles the catalog for the "to" branch
      # and then exits, without doing any 'diff' whatsoever. Support that option.
      return catalog_only(logger, options) if options[:catalog_only]

      # Set up the cached master directory - maintain it, adjust options if needed. However, if we
      # are getting the 'from' catalog from PuppetDB, then don't do this.
      unless options[:cached_master_dir].nil? || options[:from_puppetdb]
        OctocatalogDiff::CatalogUtil::CachedMasterDirectory.run(options, logger)
      end

      # bootstrap_then_exit is a special case that only prepares directories and does not
      # depend on facts. This happens within the 'catalogs' object, since bootstrapping and
      # preparing catalogs are tightly coupled operations. However this does not actually
      # build catalogs.
      if options[:bootstrap_then_exit]
        catalogs_obj = OctocatalogDiff::Util::Catalogs.new(options, logger)
        return bootstrap_then_exit(logger, catalogs_obj)
      end

      # Compile catalogs and do catalog-diff
      catalog_diff = OctocatalogDiff::API::V1.catalog_diff(options.merge(logger: logger))
      diffs = catalog_diff.diffs

      # Display diffs
      printer_obj = OctocatalogDiff::Cli::Printer.new(options, logger)
      printer_obj.printer(diffs, catalog_diff.from.compilation_dir, catalog_diff.to.compilation_dir)

      # Return the resulting diff object if requested (generally for testing) or otherwise return exit code
      return catalog_diff if opts[:INTEGRATION]
      diffs.any? ? EXITCODE_SUCCESS_WITH_DIFFS : EXITCODE_SUCCESS_NO_DIFFS
    end

    # Parse command line options with 'optparse'. Returns a hash with the parsed arguments.
    # @param argv [Array] Command line arguments (MUST be specified)
    # @return [Hash] Options
    def self.parse_opts(argv)
      options = { ignore: OctocatalogDiff::Util::Util.deep_dup(DEFAULT_IGNORES) }
      Options.parse_options(argv, options)
    end

    # Generic overrides
    def self.setup_overrides(key, options)
      o = options["#{key}_in".to_sym]
      return unless o.is_a?(Array)
      return unless o.any?
      options[key] ||= []
      options[key].concat o.map { |x| OctocatalogDiff::API::V1::Override.create_from_input(x) }
    end

    # Fact overrides come in here
    def self.setup_fact_overrides(options)
      setup_overrides(:from_fact_override, options)
      setup_overrides(:to_fact_override, options)
    end

    # ENC parameter overrides come in here
    def self.setup_enc_overrides(options)
      setup_overrides(:from_enc_override, options)
      setup_overrides(:to_enc_override, options)
    end

    # Helper method: Configure and setup logger
    def self.setup_logger(logger, options, argv_save)
      # Configure the logger
      logger.level = Logger::INFO
      logger.level = Logger::DEBUG if options[:debug]
      logger.level = Logger::ERROR if options[:quiet]

      # Some debugging information up front
      version_display = ENV['OCTOCATALOG_DIFF_CUSTOM_VERSION'] || VERSION
      logger.debug "Running octocatalog-diff #{version_display} with ruby #{RUBY_VERSION}"
      logger.debug "Command line arguments: #{argv_save.inspect}"
      logger.debug "Running on host #{Socket.gethostname} (#{RUBY_PLATFORM})"
    end

    # Compile the catalog only
    def self.catalog_only(logger, options)
      opts = options.merge(logger: logger)
      to_catalog = OctocatalogDiff::API::V1.catalog(opts)

      # If the catalog compilation failed, an exception would have been thrown. So if
      # we get here, the catalog succeeded. Dump the catalog to the appropriate place
      # and exit successfully.
      if options[:output_file]
        File.open(options[:output_file], 'w') { |f| f.write(to_catalog.to_json) }
        logger.info "Wrote catalog to #{options[:output_file]}"
      else
        puts to_catalog.to_json
      end

      return { exitcode: EXITCODE_SUCCESS_NO_DIFFS, to: to_catalog } if options[:INTEGRATION] # For integration testing
      EXITCODE_SUCCESS_NO_DIFFS
    end

    # --bootstrap-then-exit command
    def self.bootstrap_then_exit(logger, catalogs_obj)
      catalogs_obj.bootstrap_then_exit
      return EXITCODE_SUCCESS_NO_DIFFS
    rescue OctocatalogDiff::Errors::BootstrapError => exc
      logger.fatal("--bootstrap-then-exit error: bootstrap failed (#{exc})")
      return EXITCODE_FAILURE
    end
  end
end
