# frozen_string_literal: true

require_relative 'bootstrap'
require_relative 'git'
require_relative '../util/catalogs'

require 'fileutils'

module OctocatalogDiff
  module CatalogUtil
    # Handle the bootstrapped and cached checkout of [master branch]. This is an optimization
    # targeted at local development environments, since a frequent pattern is "run a catalog-diff
    # between what I have here, and master."
    #
    # Please note that there could be a race condition here if this code was run in parallel (i.e.,
    # the cached master directory is blown away and re-created when a Puppet catalog compile is in
    # progress). Do not introduce this code to an environment where catalog-diff may be running in
    # parallel unless you have accounted for this (or are willing to tolerate any errors).
    class CachedMasterDirectory
      # Set default branch. Can be overridden by options[:master_cache_branch].
      DEFAULT_MASTER_BRANCH = 'origin/master'.freeze

      # Get the master branch based on supplied options.
      # @param options [Hash] Options hash
      # @return [String] Master branch configured (defaults to DEFAULT_MASTER_BRANCH)
      def self.master_branch(options = {})
        options.fetch(:master_cache_branch, DEFAULT_MASTER_BRANCH)
      end

      # This is the entry point from the CLI (or anywhere else). Takes options hash and logger
      # as arguments, sets up the cached master directory if required, and adjusts options hash
      # accordingly. Returns nothing; raises exceptions for failures.
      # @param options [Hash] Options hash from CLI
      # @param logger [Logger] Logger object
      def self.run(options, logger)
        # If nobody asked for this, don't do anything
        return if options[:cached_master_dir].nil?

        # Verify that parameters are set up correctly and that at least one of the to-branch and
        # from-branch is [master branch]. If not, it's not worthwhile to do any of the remaining
        # tasks in this section.
        return unless cached_master_applicable_to_this_run?(options)

        # This directory was supposed to be created as part of the option setup. Make sure it exists
        # as a sanity check.
        Dir.mkdir options[:cached_master_dir], 0o755 unless Dir.exist?(options[:cached_master_dir])

        # Determine if it's necessary to check out the git repo to the directory in question.
        git_repo_checkout_bootstrap(options, logger) unless git_repo_checkout_current?(options, logger)

        # Under --bootstrap-then-exit, don't adjust the options. (Otherwise code runs twice.)
        return if options[:bootstrap_then_exit]

        # Re-point any options to the cached directory.
        %w(from to).each do |x|
          next unless options["#{x}_env".to_sym] == master_branch(options)
          logger.debug "Setting --bootstrapped-#{x}-dir=#{options[:cached_master_dir]}"
          options["bootstrapped_#{x}_dir".to_sym] = options[:cached_master_dir]
        end

        # If a catalog was already compiled for the requested node, point to it directly to avoid
        # re-compiling said catalog.
        unless options[:node].nil?
          catalog_path = File.join(options[:cached_master_dir], '.catalogs', options[:node] + '.json')
          if File.file?(catalog_path)
            %w(from to).each do |x|
              next unless options["#{x}_env".to_sym] == master_branch(options)
              next unless options["#{x}_catalog".to_sym].nil?
              logger.debug "Setting --#{x}-catalog=#{catalog_path}"
              options["#{x}_catalog".to_sym] = catalog_path
              options["#{x}_catalog_compilation_dir".to_sym] = options[:cached_master_dir]
            end
          end
        end
      end

      # Determine if the cached master directory functionality is needed at all.
      # @param options [Hash] Options hash from CLI
      # @return [Boolean] whether to-branch and/or from-branch == [master branch]
      def self.cached_master_applicable_to_this_run?(options)
        return false if options[:cached_master_dir].nil?
        target_branch = master_branch(options)
        options.fetch(:from_env, '') == target_branch || options.fetch(:to_env, '') == target_branch
      end

      # Determine whether git repo checkout in the directory is current.
      # To consider here: (a) is anything at all checked out; (b) is the correct SHA checked out?
      # @param options [Hash] Options hash from CLI
      # @param logger [Logger] Logger object
      # @return [Boolean] whether git repo checkout in the directory is current
      def self.git_repo_checkout_current?(options, logger)
        shafile = File.join(options[:cached_master_dir], '.catalog-diff-master.sha')
        return false unless File.file?(shafile)
        bootstrapped_sha = File.read(shafile)
        target_branch = master_branch(options)
        branch_sha_opts = options.merge(branch: target_branch)
        current_master_sha = OctocatalogDiff::CatalogUtil::Git.branch_sha(branch_sha_opts)
        logger.debug "Cached master dir: bootstrapped=#{bootstrapped_sha}; current=#{current_master_sha}"
        bootstrapped_sha.strip == current_master_sha.strip
      end

      # Check out [master branch] -> cached directory and bootstrap it
      # @param options [Hash] Options hash from CLI
      # @param logger [Logger] Logger object
      def self.git_repo_checkout_bootstrap(options, logger)
        # This directory isn't current so kill it
        # Too dangerous if someone slips up on the command line:
        # FileUtils.rm_rf options[:cached_master_dir] if Dir.exist?(options[:cached_master_dir])
        shafile = File.join(options[:cached_master_dir], '.catalog-diff-master.sha')
        target_branch = master_branch(options)
        branch_sha_opts = options.merge(branch: target_branch)
        current_master_sha = OctocatalogDiff::CatalogUtil::Git.branch_sha(branch_sha_opts)

        if Dir.exist?(options[:cached_master_dir]) && File.exist?(shafile)
          # If :cached_master_dir was set in a known-safe manner, safe_to_delete_cached_master_dir will
          # allow the cleanup to take place automatically.
          if options.fetch(:safe_to_delete_cached_master_dir, false) == options[:cached_master_dir]
            FileUtils.rm_rf options[:cached_master_dir] if Dir.exist?(options[:cached_master_dir])
          else
            message = "To proceed, #{options[:cached_master_dir]} needs to be deleted, so it can be re-created."\
                      " I'm not yet deemed safe enough to do this for you though. Please jump out to a shell and run"\
                      " 'rm -rf #{options[:cached_master_dir]}' and then come back and try again. (Existing SHA:"\
                      " #{File.read(shafile).strip}; current master SHA: #{current_master_sha})"
            raise Errno::EEXIST, message
          end
        end

        # This logic is similar to 'bootstrap-then-exit' (without the exit part). The
        # bootstrap_then_exit handles creating this directory.
        fake_options = options.dup
        fake_options[:bootstrap_then_exit] = true
        fake_options[:bootstrapped_from_dir] = options[:cached_master_dir]
        fake_options[:bootstrapped_to_dir] = nil
        fake_options[:from_env] = master_branch(options)

        logger.debug 'Begin bootstrap cached master directory'
        catalogs_obj = OctocatalogDiff::Util::Catalogs.new(fake_options, logger)
        catalogs_obj.bootstrap_then_exit
        logger.debug 'Success bootstrap cached master directory'

        # Write the SHA of [master branch], so git_repo_checkout_current? works next time
        File.open(shafile, 'w') { |f| f.write(current_master_sha) }
        logger.debug "Cached master directory bootstrapped to #{current_master_sha}"

        # Create <dir>/.catalogs, to save any catalogs compiled along the way
        catalog_dir = File.join(options[:cached_master_dir], '.catalogs')
        Dir.mkdir catalog_dir unless File.directory?(catalog_dir)
      end

      # Save a compiled catalog in the cached master directory. Does not die fatally if
      # catalog is invalid or this isn't set up or whatever else.
      # @param node [String] node name
      # @param dir [String] cached master directory
      # @param catalog [OctocatalogDiff::Catalog] Catalog object
      # @return [Boolean] true if catalog was saved, false if not
      def self.save_catalog_in_cache_dir(node, dir, catalog)
        return false if dir.nil? || node.nil?
        return false if catalog.nil? || !catalog.valid?

        path = File.join(dir, '.catalogs')
        return false unless Dir.exist?(path)

        filepath = File.join(path, node + '.json')
        return false if File.file?(filepath)

        File.open(filepath, 'w') { |f| f.write(catalog.catalog_json) }
        true
      end
    end
  end
end
