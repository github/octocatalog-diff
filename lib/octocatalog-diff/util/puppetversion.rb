# frozen_string_literal: true

# Helper to determine the version of Puppet

require 'fileutils'
require 'open3'
require 'shellwords'

module OctocatalogDiff
  module Util
    # This is a utility class to determine the version of Puppet.
    class PuppetVersion
      # Determine the version of Puppet.
      # @param puppet [String] Path to Puppet binary
      # @param options [Hash] Options hash as defined in OctocatalogDiff::Catalog::Computed
      # @return [String] Puppet version number
      def self.puppet_version(puppet, options = {})
        raise ArgumentError, 'Puppet binary was not supplied' if puppet.nil?
        raise Errno::ENOENT, "Puppet binary #{puppet} doesn't exist" unless File.file?(puppet)
        cmdline = [Shellwords.escape(puppet), '--version'].join(' ')

        # This is the environment provided to the puppet command.
        env = {
          'HOME' => ENV['HOME'],
          'PATH' => ENV['PATH'],
          'PWD' => File.dirname(puppet)
        }
        pass_env_vars = options.fetch(:pass_env_vars, [])
        pass_env_vars.each { |var| env[var] ||= ENV[var] }
        out, err, _status = Open3.capture3(env, cmdline, unsetenv_others: true, chdir: env['PWD'])
        return Regexp.last_match(1) if out =~ /^([\d\.]+)\s*$/
        raise "Unable to determine Puppet version: #{out} #{err}"
      end
    end
  end
end
