# Spec file that computes catalog differences for specified hosts.

require 'open3'
require 'shellwords'
require 'tempfile'

# This rspec job assumes you have passed in a list of hosts in an environment variable called HOST_LIST.
# Adjust as necessary.
hosts = ENV['HOST_LIST']
raise ArgumentError, 'Must pass a HOST_LIST' if hosts.nil? || hosts.empty?

# This rspec job assumes your puppet code resides one directory up from the location of this file.
# Adjust as necessary.
CHECKOUT_DIR = File.expand_path('..', File.dirname(__FILE__))

# Prior to starting this job, you need to check out and bootstrap the 'master' branch
# to another directory.
CACHED_MASTER_DIRECTORY = '/fill/in/this/path'.freeze

# This is the location and the arguments for octocatalog-diff. Adjust as necessary.
ARGV = [
  File.expand_path('../bin/octocatalog-diff', File.dirname(__FILE__)),
  '--bootstrapped-to-dir', CHECKOUT_DIR,
  '--bootstrapped-from-dir', CACHED_MASTER_DIRECTORY,
  '--no-color',
  '--debug',
  '--no-header',
  '--ignore', 'Anchor[*]',
  '--ignore', 'Node[*]',
  '--retry-failed-catalog', '1'
].freeze

def run_octocatalog_diff(hostname)
  argv = ARGV.dup
  argv.concat ['--hostname', hostname]
  cmd = argv.map { |x| Shellwords.escape(x) }.join(' ')
  Open3.capture2e(cmd, chdir: CHECKOUT_DIR)
end

hosts.each do |hostname|
  describe hostname.to_s do
    it 'differences' do
      exit_code, result = run_octocatalog_diff(hostname)
      expect(exit_code).to eq(0), result
    end
  end
end
