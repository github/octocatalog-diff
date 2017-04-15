# frozen_string_literal: true

require 'open3'
require 'shellwords'

module OctocatalogDiff
  # Contains bootstrap function to bootstrap a checked-out Puppet environment.
  class Bootstrap
    # Bootstrap a checked-out Puppet environment
    # @param options [Hash] Options hash:
    #        :path [String] => Directory to bootstrap
    #        :bootstrap_script [String] => Bootstrap script, relative to directory
    # @return [Hash] => [Integer] :status_code, [String] :output
    def self.bootstrap(options = {})
      # Options validation
      unless options[:path].is_a?(String)
        raise ArgumentError, 'Directory to bootstrap (:path) undefined or wrong data type'
      end
      unless File.directory?(options[:path])
        raise Errno::ENOENT, "Non-existent directory '#{options[:path]}' in bootstrap"
      end
      unless options[:bootstrap_script].is_a?(String)
        raise ArgumentError, 'Bootstrap script (:bootstrap_script) undefined or wrong data type'
      end
      bootstrap_script = File.join(options[:path], options[:bootstrap_script])
      unless File.file?(bootstrap_script)
        raise Errno::ENOENT, "Non-existent bootstrap script '#{options[:bootstrap_script]}'"
      end

      # 'env' sets up the environment variables that will be passed to the script.
      # This is a clean environment.
      env = {
        'PWD' => options[:path],
        'HOME' => ENV['HOME'],
        'PATH' => ENV['PATH'],
        'BASEDIR' => options[:basedir]
      }
      env.merge!(options[:bootstrap_environment]) if options[:bootstrap_environment].is_a?(Hash)

      # 'opts' are options passed to the Open3.capture2e command which are described
      # here: http://ruby-doc.org/stdlib-2.1.0/libdoc/open3/rdoc/Open3.html#method-c-capture2e
      # Setting { :chdir => dir } means the shelled-out script will execute in the specified directory
      # This natively avoids the need to shell out to 'cd $dir && script/bootstrap'
      opts = { chdir: options[:path], unsetenv_others: true }

      # Actually execute the command and capture the output (combined stdout and stderr).
      cmd = [bootstrap_script, options[:bootstrap_args]].compact.map { |x| Shellwords.escape(x) }.join(' ')
      output, status = Open3.capture2e(env, cmd, opts)
      {
        status_code: status.exitstatus,
        output: output
      }
    end
  end
end
