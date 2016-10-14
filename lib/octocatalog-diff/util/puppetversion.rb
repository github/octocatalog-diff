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
      # @return [String] Puppet version number
      def self.puppet_version(puppet)
        raise ArgumentError, 'Puppet binary was not supplied' if puppet.nil?
        raise Errno::ENOENT, "Puppet binary #{puppet} doesn't exist" unless File.file?(puppet)
        cmdline = [Shellwords.escape(puppet), '--version'].join(' ')
        output, _code = Open3.capture2e(cmdline)
        return Regexp.last_match(1) if output =~ /^([\d\.]+)\s*$/
        raise "Unable to determine Puppet version: #{output}"
      end
    end
  end
end
