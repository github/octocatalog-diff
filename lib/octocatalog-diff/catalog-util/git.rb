# frozen_string_literal: true

require 'rugged'

require_relative '../errors'
require_relative '../util/scriptrunner'

module OctocatalogDiff
  module CatalogUtil
    # Class to perform a git checkout (via 'git archive') of a branch from the base git
    # directory into another targeted directory.
    class Git
      # Check out a branch via 'git archive' from one directory into another.
      # @param options [Hash] Options hash:
      #          - :branch => Branch name to check out
      #          - :path => Where to check out to (must exist as a directory)
      #          - :basedir => Where to check out from (must exist as a directory)
      #          - :logger => Logger object
      def self.check_out_git_archive(options = {})
        branch = options.fetch(:branch)
        path = options.fetch(:path)
        dir = options.fetch(:basedir)
        logger = options.fetch(:logger)
        override_script_path = options.fetch(:override_script_path, nil)

        # Validate parameters
        if dir.nil? || !File.directory?(dir)
          raise OctocatalogDiff::Errors::GitCheckoutError, "Source directory #{dir.inspect} does not exist"
        end
        if path.nil? || !File.directory?(path)
          raise OctocatalogDiff::Errors::GitCheckoutError, "Target directory #{path.inspect} does not exist"
        end

        # Create and execute checkout script
        sr_opts = {
          logger: logger,
          default_script: 'git-extract/git-extract.sh',
          override_script_path: override_script_path
        }
        script = OctocatalogDiff::Util::ScriptRunner.new(sr_opts)

        sr_run_opts = {
          :working_dir             => dir,
          :pass_env_vars           => options[:pass_env_vars],
          'OCD_GIT_EXTRACT_BRANCH' => branch,
          'OCD_GIT_EXTRACT_TARGET' => path
        }

        begin
          script.run(sr_run_opts)
          logger.debug("Success git archive #{dir}:#{branch}")
        rescue OctocatalogDiff::Util::ScriptRunner::ScriptException
          raise OctocatalogDiff::Errors::GitCheckoutError, "Git archive #{branch}->#{path} failed: #{script.output}"
        end
      end

      # Determine the SHA of origin/master (or any other branch really) in the git repo
      # @param options [Hash] Options hash:
      #          - :branch => Branch name to determine SHA of
      #          - :basedir => Where to check out from (must exist as a directory)
      def self.branch_sha(options = {})
        branch = options.fetch(:branch)
        dir = options.fetch(:basedir)
        if dir.nil? || !File.directory?(dir)
          raise Errno::ENOENT, "Git directory #{dir.inspect} does not exist"
        end
        repo = Rugged::Repository.new(dir)
        repo.branches[branch].target_id
      end
    end
  end
end
