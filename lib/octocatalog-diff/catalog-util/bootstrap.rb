# frozen_string_literal: true

require_relative '../bootstrap'
require_relative '../errors'
require_relative '../util/parallel'
require_relative 'git'

require 'fileutils'

module OctocatalogDiff
  module CatalogUtil
    # Methods to bootstrap a directory. Intended to be called from cli. This handles
    # parallelization of bootstrap, and formats arguments as expected by the higher level bootstrap
    # script.
    class Bootstrap
      # Bootstrap directories specified by --bootstrapped-from-dir and --bootstrapped-to-dir
      # command line options. Bootstrapping occurs in parallel. This takes no parameters (options come
      # from options) and returns nothing (it raises an exception if something fails).
      def self.bootstrap_directory_parallelizer(options, logger)
        # What directories do we have to bootstrap?
        dirs = []

        unless options[:bootstrapped_from_dir].nil?
          if options[:from_env] == '.'
            message = 'Must specify a from-branch other than . when using --bootstrapped-from-dir!' \
                      ' Please use "-f <from_branch>" argument.'
            logger.error(message)
            raise OctocatalogDiff::Errors::BootstrapError, message
          end

          opts = options.merge(branch: options[:from_env],
                               path: options[:bootstrapped_from_dir],
                               tag: 'from_dir',
                               dir: options[:basedir])
          dirs << opts
        end

        unless options[:bootstrapped_to_dir].nil?
          if options[:to_env] == '.'
            message = 'Must specify a to-branch other than . when using --bootstrapped-to-dir!' \
                      ' Please use "-t <to_branch>" argument.'
            logger.error(message)
            raise OctocatalogDiff::Errors::BootstrapError, message
          end

          opts = options.merge(branch: options[:to_env],
                               path: options[:bootstrapped_to_dir],
                               tag: 'to_dir')
          dirs << opts
        end

        # If there are no directories given, advise the user to supply the necessary options
        if dirs.empty?
          return unless options[:cached_master_dir].nil?
          message = 'Specify one or more of --bootstrapped-from-dir / --bootstrapped-to-dir / --cached-master-dir' \
                    ' when using --bootstrap_then_exit'
          logger.error(message)
          raise OctocatalogDiff::Errors::BootstrapError, message
        end

        # Bootstrap the directories in parallel. Since there are no results here that we
        # care about, increment the success counter for each run that did not throw an exception.
        tasks = dirs.map do |x|
          OctocatalogDiff::Util::Parallel::Task.new(
            method: method(:bootstrap_directory),
            description: "bootstrap #{x[:tag]} #{x[:path]} for #{x[:branch]}",
            args: x
          )
        end

        logger.debug("Begin #{dirs.size} bootstrap(s)")
        parallel_tasks = OctocatalogDiff::Util::Parallel.run_tasks(tasks, logger, options[:parallel])
        parallel_tasks.each do |result|
          if result.status
            logger.debug("Success bootstrap_directory for #{result.args[:tag]}")
          else
            errmsg = "Failed bootstrap_directory for #{result.args[:tag]}: #{result.exception.class} #{result.exception.message}"
            raise OctocatalogDiff::Errors::BootstrapError, errmsg
          end
        end
      end

      # Performs the actual bootstrap of a directory. Intended to be called by bootstrap_directory_parallelizer
      # above, or as part of the parallelized catalog build process from util/catalogs.
      # @param logger [Logger] Logger object
      # @param dir_opts [Hash] Directory options: branch, path, tag
      def self.bootstrap_directory(options, logger)
        raise ArgumentError, ':path must be supplied' unless options[:path]
        FileUtils.mkdir_p(options[:path]) unless Dir.exist?(options[:path])
        git_checkout(logger, options) if options[:branch]
        unless options[:bootstrap_script].nil?
          install_bootstrap_script(logger, options)
          run_bootstrap(logger, options)
        end
      end

      # Perform git checkout
      # @param logger [Logger] Logger object
      # @param dir_opts [Hash] Directory options: branch, path, tag
      def self.git_checkout(logger, dir_opts)
        logger.debug("Begin git checkout #{dir_opts[:basedir]}:#{dir_opts[:branch]} -> #{dir_opts[:path]}")
        OctocatalogDiff::CatalogUtil::Git.check_out_git_archive(dir_opts.merge(logger: logger))
        logger.debug("Success git checkout #{dir_opts[:basedir]}:#{dir_opts[:branch]} -> #{dir_opts[:path]}")
      rescue OctocatalogDiff::Errors::GitCheckoutError => exc
        logger.error("Git checkout error: #{exc}")
        raise OctocatalogDiff::Errors::BootstrapError, exc
      end

      # Install bootstrap script in the target directory. This allows proper bootstrapping from the
      # latest version of the script, not the script that was in place at the time that directory's branch
      # was committed.
      # @param logger [Logger] Logger object
      # @param opts [Hash] Directory options
      def self.install_bootstrap_script(logger, opts)
        # Verify that bootstrap file exists
        src = if opts[:bootstrap_script].start_with? '/'
          opts[:bootstrap_script]
        else
          File.join(opts[:basedir], opts[:bootstrap_script])
        end
        raise OctocatalogDiff::Errors::BootstrapError, "Bootstrap script #{src} does not exist" unless File.file?(src)

        logger.debug('Begin install bootstrap script in target directory')

        # Create destination directory if needed
        dest = File.join(opts[:path], opts[:bootstrap_script])
        dest_dir = File.dirname(dest)
        FileUtils.mkdir_p(dest_dir) unless File.directory?(dest_dir)

        # Copy file and make executable
        FileUtils.cp src, dest
        FileUtils.chmod 0o755, dest
        logger.debug("Success: copied #{src} to #{dest}")
      end

      # Execute the bootstrap.
      # @param logger [Logger] Logger object
      # @param opts [Hash] Directory options
      def self.run_bootstrap(logger, opts)
        logger.debug("Begin bootstrap with '#{opts[:bootstrap_script]}' in #{opts[:path]}")
        result = OctocatalogDiff::Bootstrap.bootstrap(opts)
        if opts[:debug_bootstrap] || result[:status_code] > 0
          output = result[:output].split(/[\r\n]+/)
          output.each { |x| logger.debug("Bootstrap: #{x}") }
        end
        unless (result[:status_code]).zero?
          raise OctocatalogDiff::Errors::BootstrapError, "bootstrap failed for #{opts[:path]}: #{result[:output]}"
        end
        logger.debug("Success bootstrap in #{opts[:path]}")
        result[:output]
      end
    end
  end
end
