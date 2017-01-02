# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'shellwords'
require 'tempfile'

module OctocatalogDiff
  module CatalogUtil
    class ENC
      # Support an ENC that executes a script on this system which returns the ENC data on STDOUT.
      class Script
        attr_reader :content, :error_message, :script

        # Constructor
        # @param options [Hash] Options - must contain script name and node name, plus tempdir if it's a relative path
        def initialize(options)
          # Make sure the node is in the options
          raise ArgumentError, 'OctocatalogDiff::CatalogUtil::ENC::Script#new requires :node' unless options.key?(:node)
          @node = options[:node]

          # Determine path to ENC and make sure it exists
          raise ArgumentError, 'OctocatalogDiff::CatalogUtil::ENC::Script#new requires :enc' unless options.key?(:enc)
          @script = script_path(options[:enc], options[:tempdir])

          # Other options we may recognize
          @pass_env_vars = options.fetch(:pass_env_vars, [])

          # Initialize the content and error message
          @content = nil
          @error_message = 'The execute method was never run'
        end

        # Executor
        # @param logger [Logger] Logger object
        def execute(logger)
          logger.debug "Beginning OctocatalogDiff::CatalogUtil::ENC::Script#execute for #{@node} with #{@script}"
          logger.debug "Passing these extra environment variables: #{@pass_env_vars}" if @pass_env_vars.any?

          # Copy the script and make it executable
          # Then run the command in the restricted environment
          raise Errno::ENOENT, "ENC #{@script} wasn't found" unless File.file?(@script)
          file = Tempfile.open('enc.sh')
          file.close
          begin
            FileUtils.cp @script, file.path
            FileUtils.chmod 0o755, file.path
            env = {
              'HOME' => ENV['HOME'],
              'PATH' => ENV['PATH'],
              'PWD' => File.dirname(@script)
            }
            @pass_env_vars.each { |var| env[var] ||= ENV[var] }
            command = [file.path, @node].map { |x| Shellwords.escape(x) }.join(' ')
            out, err, status = Open3.capture3(env, command, unsetenv_others: true, chdir: File.dirname(@script))
            logger.debug "ENC exited #{status.exitstatus}: #{out.length} bytes to STDOUT, #{err.length} bytes to STDERR"
          ensure
            file.unlink
          end

          # Analyze the output
          if status.exitstatus.zero?
            @content = out
            @error_message = nil
            logger.warn "ENC STDERR: #{err}" unless err.empty?
          else
            @content = nil
            @error_message = "ENC failed with status #{status.exitstatus}: #{out} #{err}"
            logger.error "ENC failed - Status #{status.exitstatus}"
            logger.error "Failed ENC printed this to STDOUT: #{out}" unless out.empty?
            logger.error "Failed ENC printed this to STDERR: #{err}" unless err.empty?
          end
        end

        private

        # Determine the script path for the incoming file -- absolute or relative
        # @param enc [String] Path to ENC supplied by user/config
        # @param tempdir [String]
        # @return [String] Full path to file on system
        def script_path(enc, tempdir)
          return enc if enc.start_with? '/'
          raise ArgumentError, 'OctocatalogDiff::CatalogUtil::ENC::Script#new requires :tempdir' unless tempdir.is_a?(String)
          return File.join(tempdir, enc) if enc =~ %r{^environments/[^/]+/}
          File.join(tempdir, 'environments', 'production', enc)
        end
      end
    end
  end
end
