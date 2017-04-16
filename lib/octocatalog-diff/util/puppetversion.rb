# frozen_string_literal: true

# Helper to determine the version of Puppet

require_relative 'scriptrunner'

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

        sr_opts = {
          default_script: 'puppet/puppet.sh',
          override_script_path: options[:override_script_path]
        }

        script = OctocatalogDiff::Util::ScriptRunner.new(sr_opts)

        sr_run_opts = {
          :logger             => options[:logger],
          :working_dir        => File.dirname(puppet),
          :pass_env_vars      => options[:pass_env_vars],
          :argv               => '--version',
          'OCD_PUPPET_BINARY' => puppet
        }

        output = script.run(sr_run_opts)
        return Regexp.last_match(1) if output =~ /^([\d\.]+)\s*$/
        # :nocov:
        raise "Unable to determine Puppet version: #{script.output}"
        # :nocov:
      end
    end
  end
end
