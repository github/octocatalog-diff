require_relative '../tests/spec_helper'
require OctocatalogDiff::Spec.require_path('/cli')
require OctocatalogDiff::Spec.require_path('/errors')

require 'json'
require 'open3'
require 'ostruct'
require 'shellwords'
require 'stringio'
require 'tempfile'

module OctocatalogDiff
  class Integration
    # Test with a puppetdb fact server
    def self.integration_with_puppetdb(server_opts, opts)
      server_opts[:rsa_key] ||= File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/server.key'))
      server_opts[:cert] ||= File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/server.crt'))
      test_server = nil
      3.times do
        test_server = SSLTestServer.new(server_opts)
        test_server.start
        break if test_server.port > 0
      end
      raise OctocatalogDiff::Spec::FixtureError, 'Unable to instantiate SSLTestServer' unless test_server.port > 0
      puppetdb_url_save = ENV['PUPPETDB_URL']
      ENV['PUPPETDB_URL'] = "https://localhost:#{test_server.port}"
      integration(opts)
    ensure
      test_server.stop
      ENV['PUPPETDB_URL'] = puppetdb_url_save
    end

    # For an integration test, run the full CLI and get results
    def self.integration_cli(argv)
      script = File.expand_path('../../../bin/octocatalog-diff', File.dirname(__FILE__))
      cmdline = [script, argv].flatten.map { |x| Shellwords.escape(x) }.join(' ')
      env = { 'OCTOCATALOG_DIFF_CONFIG_FILE' => OctocatalogDiff::Spec.fixture_path('cli-configs/no-op.rb') }
      stdout, stderr, status = Open3.capture3(env, cmdline)
      OpenStruct.new(
        stdout: stdout,
        stderr: stderr,
        exitcode: status.exitstatus
      )
    end

    # For an integration test, run catalog-diff and get results
    def self.integration(options = {})
      # Passed argv -- can be a string or an array
      argv = if options[:argv].is_a?(Array)
        argv_value = options[:argv]
        options.delete(:argv)
        argv_value
      elsif options[:argv].is_a?(String)
        argv_value = Shellwords.split(options[:argv])
        options.delete(:argv)
        argv_value
      else
        []
      end

      # Fact file helper
      if options[:spec_fact_file]
        argv << '--fact-file'
        argv << OctocatalogDiff::Spec.fixture_path("facts/#{options[:spec_fact_file]}")
        options.delete(:fact_file)
      end

      # Repo fixture helper
      if options[:spec_repo]
        options[:bootstrapped_from_dir] = OctocatalogDiff::Spec.fixture_path("repos/#{options[:spec_repo]}")
        options[:bootstrapped_to_dir] = OctocatalogDiff::Spec.fixture_path("repos/#{options[:spec_repo]}")
        options[:basedir] = OctocatalogDiff::Spec.fixture_path("repos/#{options[:spec_repo]}")
        options.delete(:spec_repo)
      end

      if options[:spec_repo_old]
        options[:bootstrapped_from_dir] = OctocatalogDiff::Spec.fixture_path("repos/#{options[:spec_repo_old]}")
        options[:basedir] = OctocatalogDiff::Spec.fixture_path("repos/#{options[:spec_repo_old]}")
        options.delete(:spec_repo_old)
      end

      if options[:spec_repo_new]
        options[:bootstrapped_to_dir] = OctocatalogDiff::Spec.fixture_path("repos/#{options[:spec_repo_new]}")
        options[:basedir] = OctocatalogDiff::Spec.fixture_path("repos/#{options[:spec_repo_new]}")
        options.delete(:spec_repo_new)
      end

      # Already-compiled catalogs
      if options[:spec_catalog_old]
        options[:from_catalog] = OctocatalogDiff::Spec.fixture_path("catalogs/#{options[:spec_catalog_old]}")
        raise Errno::ENOENT, 'Invalid :spec_catalog_old' unless File.file?(options[:from_catalog])
      end

      if options[:spec_catalog_new]
        options[:to_catalog] = OctocatalogDiff::Spec.fixture_path("catalogs/#{options[:spec_catalog_new]}")
        raise Errno::ENOENT, 'Invalid :spec_catalog_new' unless File.file?(options[:to_catalog])
      end

      # ENC datafile
      if options[:enc_datafile]
        tf = Tempfile.open('enc.sh')
        tf.write "#!/bin/sh\n"
        tf.write "cat <<-EOF\n"
        tf.write OctocatalogDiff::Spec.fixture_read("enc/#{options[:enc_datafile]}")
        tf.write "EOF\n"
        tf.close
        options[:enc] = tf.path
        options.delete(:enc_datafile)
      end

      # Other defaults
      options[:debug] = true
      options[:from_puppet_binary] ||= OctocatalogDiff::Spec::PUPPET_BINARY
      options[:to_puppet_binary] ||= OctocatalogDiff::Spec::PUPPET_BINARY
      options[:parallel] = false if ENV['COVERAGE']
      options[:INTEGRATION] = true

      # Run octocatalog-diff CLI method. Capture stdout and stderr using 'strio'.
      # Set options[:RETURN_DIFFS] so that the .cli method returns the JSON array
      # of differences instead of the exit code.
      logger, logger_string = OctocatalogDiff::Spec.setup_logger
      begin
        # Capture stdout to a variable
        old_out = $stdout
        stdout_strio = StringIO.new
        $stdout = stdout_strio

        # Run the OctocatalogDiff::Cli.cli and validate output format.
        result = OctocatalogDiff::Cli.cli(argv, logger, options)

        unless result.is_a?(OpenStruct)
          raise "Expected OpenStruct, got #{result.inspect} from OctocatalogDiff::Cli.cli!"
        end

        OpenStruct.new(
          logs: logger_string.string,
          log_messages: logger_string.string.split(/\n/).map { |x| OctocatalogDiff::Spec.strip_log_message(x) },
          output: stdout_strio.string,
          diffs: result.diffs,
          to: result.to,
          from: result.from,
          exitcode: result.diffs.any? ? 2 : 0,
          options: options
        )
      rescue => exc # Yes, rescue *everything*
        OpenStruct.new(
          exitcode: -1,
          exception: exc,
          logs: logger_string.string,
          output: stdout_strio.string,
          diffs: []
        )
      ensure
        $stdout = old_out
      end
    end

    # Format an exception and log messages into a more useful human-readable format.
    def self.format_exception(result)
      return nil unless result[:exception]
      result[:logs] ||= '(none)'
      [
        'Catalog compilation failed',
        "\t#{result[:exception].class}: #{result[:exception].message}",
        "\t" + result[:exception].backtrace.join("\n\t"),
        'Compile logs:',
        "\t" + result[:logs].split("\n").map(&:strip).join("\n\t")
      ].join("\n")
    end
  end
end
