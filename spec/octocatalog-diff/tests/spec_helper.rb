require 'fileutils'
require 'logger'
require 'rspec'
require 'rspec/retry'
require 'tempfile'

# Enable SimpleCov coverage testing?
if ENV['COVERAGE']
  require 'simplecov'
  require 'simplecov-erb'
  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::ERBFormatter
  ]
  SimpleCov.start do
    # don't show specs as missing coverage for themselves
    add_filter '/spec/octocatalog-diff/'
    # external things are external
    add_filter '/lib/octocatalog-diff/external/'
    # simplecov doesn't properly show coverage inside optparse blocks
    add_filter '/lib/octocatalog-diff/cli/options/'
  end
end

# For testing SSL and PuppetDB
Dir[File.expand_path(File.join(File.dirname(__FILE__), '..', 'support', '**', '*.rb'))].each { |f| require f }

# Enable rspec-retry
RSpec.configure do |config|
  config.verbose_retry = true
  config.display_try_failure_messages = true
end

module OctocatalogDiff
  class Spec
    # Set up a logger that is usable across parent and child forks.
    # This is implemented as a file rather than StringIO because StringIO doesn't reopen, and
    # therefore loses the content of the child process. File handles on an actual file are not
    # limited in this way.
    class CustomLogger
      attr_accessor :logger

      def initialize
        @tf = Tempfile.new('customlogger.log')
        @tf.close
        at_exit { @tf.unlink }

        @logger = Logger.new @tf.path
        @logger.level = Logger::DEBUG
      end

      def string
        # Written as an exception handler, rather than File.file?, because in some tests File.file? is mocked.
        @content ||= begin
          content = File.read(@tf.path)
          content.sub(/\A# Logfile created .+\n/, '')
        rescue Errno::ENOENT
          ''
        end
      end
    end

    # Create a logger object so that its result can be inspected
    def self.setup_logger
      logger_obj = OctocatalogDiff::Spec::CustomLogger.new
      [logger_obj.logger, logger_obj]
    end

    # Wrapper around puppet binstub
    PUPPET_BINARY = File.expand_path('../../../script/puppet', File.dirname(__FILE__)).freeze
    raise "Puppet binary (#{PUPPET_BINARY}) is missing" unless File.file?(PUPPET_BINARY)

    # An error to raise if a fixture fails but code doesn't
    class FixtureError; end

    # One 'require' to rule them all. Find the code relative to the directory
    # of this spec file, so we can easily update this to reflect packaging changes.
    def self.require_path(path)
      File.expand_path("../../../lib/octocatalog-diff/#{path}", File.dirname(__FILE__))
    end

    # Get absolute path of a file or directory in the fixture directory
    # @param fixture_filename [String] File name
    # @return [String] Full filename
    def self.fixture_path(fixture_filename)
      File.expand_path("../fixtures/#{fixture_filename}", File.dirname(__FILE__))
    end

    # Read a file from the fixture directory
    # @param fixture_filename [String] File name
    # @return [String] Full filename
    def self.fixture_read(fixture_filename)
      File.read(fixture_path(fixture_filename))
    end

    # Count the instances of a 'type' in a catalog
    # @param resources [Array] Array of resources
    # @param type [String] Type to count
    # @return [Integer] Number of instances of 'type' found
    def self.count_by_type(resources, type)
      raise "resources is not an array; it's a(n): #{resources.class}!" unless resources.is_a?(Array)
      counter = 0
      resources.each { |r| counter += 1 if r[1].split(/\f/, 3)[0].casecmp(type).zero? }
      counter
    end

    # Determine if the catalog contains a resource with a certain type and title
    # @param resources [Array] Array of resources
    # @param type [String] Type
    # @param title [String] Title
    # @return [Boolean] Whether array contains resource with type and title specified
    def self.contains_type_and_title?(resources, type, title)
      !resources.select do |x|
        test_type, test_title = x[1].split(/\f/)
        test_type.casecmp(type).zero? && test_title.casecmp(title).zero?
      end.size.zero?
    end

    # Construct a catalog that contains one or more resources
    # @param resources [Array] Catalog resources
    # @return [OctocatalogDiff::Catalog] Catalog object
    def self.build_catalog(resources)
      raise ArgumentError, 'Argument to build_catalog must be an array' unless resources.is_a?(Array)
      catalog_obj = {
        'document_type' => 'Catalog',
        'data' => {
          'name' => 'my.rspec.node',
          'resources' => resources
        },
        'metadata' => { 'api_version' => 1 }
      }
      OctocatalogDiff::Catalog.create(json: JSON.generate(catalog_obj))
    end

    # Deep copy hash / array
    # @param input [Array|Hash] Input
    # @return [Array|Hash] Deep-copied item
    def self.deep_copy(input)
      return input.map { |x| deep_copy(x) } if input.is_a?(Array)
      return input unless input.is_a?(Hash)
      result = {}
      input.each { |k, v| result[k] = deep_copy(v) }
      result
    end

    # Determine if an array of arrays contains an array starting with the lookup array. That's a mouthful
    # but it's the most accurate description. See code for details
    # @param subject [Array] Array of arrays
    # @param lookup [Array] Array to look for
    # @return [Boolean] Whether first array contains lookup array
    def self.array_contains_partial_array?(subject, lookup)
      subject.each do |x|
        return true if x.slice(0, lookup.size) == lookup
      end
      false
    end

    # Determine if a OctocatalogDiff::API::V1::Diff (or an array of those) matches a lookup hash. This
    # returns true if the object (or any object in the array) matches all keys given in the lookup hash.
    # @param diff_in [OctocatalogDiff::API::V1::Diff or Array<OctocatalogDiff::API::V1::Diff>] diff(s) to search
    # @param lookup [Hash] Lookup hash
    def self.diff_match?(diff_in, lookup)
      diffs = [diff_in].flatten
      diffs.each do |diff|
        flag = true
        lookup.to_h.each do |key, val|
          unless diff.send(key) == val
            flag = false
            break
          end
        end
        return true if flag
      end
      false
    end

    # Mock out a small shell script that tests for environment variable setting.
    # This takes the LAST command line argument, gets the value of that variable,
    # and prints it to STDERR.
    # @param filename [String] File name, relative to 'script' directory
    # @return [String] Path to temporary directory with script
    def self.shell_script_for_envvar_testing(filename)
      temp_repo_dir = Dir.mktmpdir
      Dir.mkdir(File.join(temp_repo_dir, 'script'))
      File.open(File.join(temp_repo_dir, 'script', filename), 'w') do |f|
        f.write "#!/usr/bin/env bash\n"
        f.write "var=\"${@: -1}\"\n"
        f.write "if [ \"$var\" = \"\" ]; then exit 31; fi\n"
        f.write "eval answer=\\$$var\n"
        f.write ">&2 echo $answer\n"
        f.write "exit 32\n"
      end
      File.chmod 0o755, File.join(temp_repo_dir, 'script', filename)
      temp_repo_dir
    end

    # Test whether command is available to be run. Some tests depend on git, tar, bash, etc. to be available.
    # This helps mark those tests as pending if the underlying required utility is not present or not working.
    # @param command [String] Command to test
    # @return [String] Error message from testing command (returns nil if command was successful)
    def self.test_command(command)
      output, exitcode = Open3.capture2e(command)
      return nil if exitcode.exitstatus.zero?
      return output
    rescue Errno::ENOENT => exc
      return "Errno::ENOENT: #{exc}"
    end

    # Check out fixture repo. The repository is a tarball; this extracts it to a temporary directory and returns
    # the path where it was checked out. If the checkout fails, returns nil. Note: Be sure to include code in the
    # caller to clean up the temporary directory upon exit.
    # @param repo [String] Name of repository (in fixtures/git-repos/{repo}.tar)
    # @return [String] Path to checkout
    def self.extract_fixture_repo(repo)
      # If tar isn't here, don't do this
      has_tar = test_command('tar --version')
      return nil unless has_tar.nil?

      # Make sure tarball is there
      repo_tarball = fixture_path("git-repos/#{repo}.tar")
      raise Errno::ENOENT, "Repo tarball for #{repo} not found in #{repo_tarball}" unless File.file?(repo_tarball)

      # Extract to temporary directory
      extract_dir = Dir.mktmpdir
      cmd = "tar -xf #{Shellwords.escape(repo_tarball)}"
      extract_result, extract_code = Open3.capture2e(cmd, chdir: extract_dir)
      return extract_dir if extract_code.exitstatus.zero?
      raise "Failed to extract #{repo_tarball}: #{extract_result} (#{extract_code.exitstatus})"
    end

    # Clean up a temporary directory. This does nothing if the directory doesn't exist, or if it's nil.
    # @param dir_in [String | Array<String>] Full path to directory
    def self.clean_up_tmpdir(*dir_in)
      dir_in.each do |dir|
        next if dir.nil?
        next unless File.directory?(dir)
        FileUtils.remove_entry_secure dir
      end
    end

    # To help test a diff against an answer without considering the file and line locations,
    # remove the file and line locations. This takes the JSON result from catalog-diff and returns
    # a cleaned-up array of diffs.
    def self.remove_file_and_line(diff)
      if diff.is_a?(OctocatalogDiff::API::V1::Diff)
        result = diff.to_h.dup
        %w(new_location old_location new_line old_line new_file old_file).each { |x| result.delete(x.to_sym) }
        return result
      end
      if diff.is_a?(Hash)
        result = diff.dup
        %w(new_location old_location new_line old_line new_file old_file).each { |x| result.delete(x) }
        return result
      end
      obj = diff if diff.is_a?(Array)
      obj = diff['diff'] if diff.is_a?(Hash) && diff.key?('diff')
      raise ArgumentError, diff.inspect unless obj.is_a?(Array)
      obj.map { |x| x[0] =~ /^[\-\+]$/ ? x[0..2] : x[0..3] }
    end

    # Strip off timestamps and other extraneous content from log messages so that matching
    # of individual elements can be done via string and not regexp.
    def self.strip_log_message(message)
      return message unless message.strip =~ /\A\w,\s*\[[^\]]+\]\s+(\w+)\s*--\s*:(.+)/
      "#{Regexp.last_match(1)} - #{Regexp.last_match(2).strip}"
    end

    # Get the Puppet version from the Puppet binary
    def self.puppet_version
      require require_path('util/puppetversion')
      @puppet_version ||= OctocatalogDiff::Util::PuppetVersion.puppet_version(PUPPET_BINARY)
    end

    # Mock PuppetDB facts
    def self.mock_puppetdb_fact_response(hostname)
      fixture_file = OctocatalogDiff::Spec.fixture_path(File.join('facts', "#{hostname}.yaml"))
      return [] unless File.file?(fixture_file)

      # Read the fact file to memory. Remove the first line (e.g. '!ruby/object:Puppet::Node::Facts')
      # so it doesn't try to load in all of puppet.
      fact_file = File.read(fixture_file).split(/\n/)
      fact_file[0] = '---'
      facts_in = YAML.load(fact_file.join("\n"))
      return [] unless facts_in.key?('values') && facts_in['values'].is_a?(Hash)

      # Convert the hash into an array of { 'name' => ..., 'value' => ... } pairs
      # and return it.
      facts_in['values'].keys.map { |k| { 'name' => k, 'value' => facts_in['values'][k] } }.to_json
    end

    # Helper functions to determine which major version of Puppet we are working with:
    def self.major_version
      puppet_version && puppet_version.split('.')[0].to_i
    end
  end
end
