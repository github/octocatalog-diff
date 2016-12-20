# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'rugged'
require 'shellwords'
require 'tempfile'

module OctocatalogDiff
  module CatalogUtil
    # Class to perform a git checkout (via 'git archive') of a branch from the base git
    # directory into another targeted directory.
    class Git
      # Trapped errors
      class GitCheckoutError < RuntimeError
      end

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

        # Validate parameters
        raise GitCheckoutError, "Source directory #{dir.inspect} does not exist" if dir.nil? || !File.directory?(dir)
        raise GitCheckoutError, "Target directory #{path.inspect} does not exist" if dir.nil? || !File.directory?(path)

        # To get the options working correctly (-o pipefail in particular) this needs to run under
        # bash. It's just creating a script, rather than figuring out all the shell escapes...
        begin
          tmp_script = Tempfile.new(['git-checkout', '.sh'])
          tmp_script.write "#!/bin/bash\n"
          tmp_script.write "set -euf -o pipefail\n"
          tmp_script.write "git archive --format=tar #{Shellwords.escape(branch)} | \\\n"
          tmp_script.write "  ( cd #{Shellwords.escape(path)} && tar -xf - )\n"
          tmp_script.close
          FileUtils.chmod 0o755, tmp_script.path

          logger.debug("Begin git archive #{dir}:#{branch} -> #{path}")
          output, status = Open3.capture2e(tmp_script.path, chdir: dir)
          raise GitCheckoutError, "Git archive #{branch}->#{path} failed: #{output}" unless status.exitstatus.zero?
          logger.debug("Success git archive #{dir}:#{branch}")
        ensure
          FileUtils.rm_f tmp_script.path if File.exist?(tmp_script.path)
        end
      end

      # Determine the SHA of origin/master (or any other branch really) in the git repo
      # @param options [Hash] Options hash:
      #          - :branch => Branch name to determine SHA of
      #          - :basedir => Where to check out from (must exist as a directory)
      def self.branch_sha(options = {})
        branch = options.fetch(:branch)
        dir = options.fetch(:basedir)
        raise GitCheckoutError, "Git directory #{dir.inspect} does not exist" if dir.nil? || !File.directory?(dir)
        repo = Rugged::Repository.new(dir)
        repo.branches[branch].target_id
      end
    end
  end
end
