# Spec file that compiles a number of catalogs for representative hosts, to make sure
# all of the catalogs compile correctly.

require 'open3'
require 'rspec'
require 'shellwords'

# This rspec job assumes you have passed in a list of hosts in an environment variable called HOST_LIST.
# Adjust as necessary.
hosts = ENV['HOST_LIST']
raise ArgumentError, 'Must pass a HOST_LIST' if hosts.nil? || hosts.empty?

# This rspec job assumes your puppet code resides one directory up from the location of this file.
# Adjust as necessary.
CHECKOUT_DIR = File.expand_path('..', File.dirname(__FILE__))

# This is the location and the arguments for octocatalog-diff. Adjust as necessary.
ARGV = [
  File.expand_path('../bin/octocatalog-diff', File.dirname(__FILE__)),
  '--catalog-only',
  '--bootstrapped-to-dir', CHECKOUT_DIR,
  '--no-color',
  '--debug',
  '--no-header',
  '--retry-failed-catalog', '1',
  '-o', '/dev/null' # Throw away the JSON blob we aren't displaying anyway
].freeze

# Set this environment variable to the location of your configuration file.
ENV['OCTOCATALOG_DIFF_CONFIG_FILE'] = File.expand_path('../.octocatalog-diff.cfg.rb', File.dirname(__FILE__))

def run_octocatalog_diff(hostname)
  argv = ARGV.dup
  argv.concat ['--hostname', hostname]
  cmd = argv.map { |x| Shellwords.escape(x) }.join(' ')
  Open3.capture2e(cmd, chdir: CHECKOUT_DIR)
end

hosts.split(',').each do |hostname|
  describe "catalog for #{hostname}" do
    it 'compiles' do
      output, status = run_octocatalog_diff(hostname)
      expect(status.exitstatus).to eq(0), output
    end
  end
end
