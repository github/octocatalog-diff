require 'fileutils'
require 'open3'
require 'shellwords'
require_relative '../lib/octocatalog-diff/version'

module OctocatalogDiff
  # A class to contain methods and constants for cleaner code
  class Gem
    # Override version number from the environment
    def self.version
      version = ENV['OCTOCATALOG_DIFF_VERSION'] || OctocatalogDiff::Version::VERSION
      unless version == OctocatalogDiff::Version::VERSION
        warn "WARNING: Using version #{version}, not #{OctocatalogDiff::Version::VERSION}"
      end
      version
    end

    BASEDIR = File.expand_path('..', File.dirname(__FILE__)).freeze
    VERSION = version.freeze
    GEMFILE = "octocatalog-diff-#{VERSION}.gem".freeze
    PKGDIR = File.join(BASEDIR, 'pkg').freeze
    OUTFILE = File.join(BASEDIR, GEMFILE).freeze
    FINAL_GEMFILE = File.join(PKGDIR, GEMFILE).freeze

    # Determine what branch we are on
    def self.branch
      output = exec_command('git rev-parse --abbrev-ref HEAD')
      output.strip
    end

    # Build the gem and put it into the 'pkg' directory
    def self.build(target = GEMFILE)
      exec_command('gem build octocatalog-diff.gemspec')
      raise "gem failed to create expected output file: #{OUTFILE}" unless File.file?(OUTFILE)

      Dir.mkdir PKGDIR unless File.directory?(PKGDIR)
      FileUtils.mv OUTFILE, File.join(PKGDIR, target)
      puts "Generated #{File.join(PKGDIR, target)}"
    ensure
      # Clean up the *.gem generated in the main directory if it's still there
      FileUtils.rm OUTFILE if File.file?(OUTFILE)
    end

    # Push the gem to rubygems
    def self.push
      raise 'Cannot push version that does not match .version file' unless version == OctocatalogDiff::Version::VERSION
      raise "The gem file doesn't exist: #{FINAL_GEMFILE}" unless File.file?(FINAL_GEMFILE)
      exec_command("gem push #{Shellwords.escape(FINAL_GEMFILE)}")
    end

    # Tag the release on GitHub
    def self.tag
      raise 'Cannot tag version that does not match .version file' unless version == OctocatalogDiff::Version::VERSION

      # Make sure we have not released this version before
      exec_command('git fetch -t origin')
      tags = exec_command('git tag -l').split(/\n/)
      raise "There is already a #{VERSION} tag" if tags.include?(VERSION)

      # Tag it
      exec_command("git tag #{Shellwords.escape(VERSION)}")
      exec_command('git push origin master')
      exec_command("git push origin #{Shellwords.escape(VERSION)}")
    end

    # Yank gem from rubygems
    def self.yank
      exec_command("gem yank octocatalog-diff -v #{Shellwords.escape(VERSION)}")
    end

    # Utility method: Execute command
    def self.exec_command(command)
      STDERR.puts "Command: #{command}"
      output, code = Open3.capture2e(command, chdir: BASEDIR)
      return output if code.exitstatus.zero?
      STDERR.puts "Output:\n#{output}"
      STDERR.puts "Exit code: #{code.exitstatus}"
      exit code.exitstatus
    end
  end
end

namespace :gem do
  task 'build' do
    branch = OctocatalogDiff::Gem.branch
    raise "On a non-master branch #{branch}; use gem:force-build if you really want to do this" unless branch == 'master'
    OctocatalogDiff::Gem.build
  end

  task 'force-build' do
    branch = OctocatalogDiff::Gem.branch
    unless branch == 'master'
      warn "WARNING: Force-building from non-master branch #{branch}"
    end

    version = OctocatalogDiff::Gem.version
    OctocatalogDiff::Gem.build("octocatalog-diff-#{version}-#{branch}.gem")
  end

  task 'push' do
    OctocatalogDiff::Gem.push
  end

  task 'release' do
    branch = OctocatalogDiff::Gem.branch
    raise "On a non-master branch #{branch}; refusing to release" unless branch == 'master'

    # Build the options parser documentation and fail if it changed
    filename = File.expand_path('../doc/optionsref.md', File.dirname(__FILE__))
    old_optparse = File.read(filename)
    Rake::Task['doc:build'].invoke
    new_optparse = File.read(filename)

    if old_optparse != new_optparse
      File.open(filename, 'w') { |f| f.write(old_optparse) }
      raise 'You have not run `rake doc:build` to build the optparse documentation for this release'
    end

    [:build, :tag, :push].each { |t| Rake::Task["gem:#{t}"].invoke }
  end

  task 'tag' do
    branch = OctocatalogDiff::Gem.branch
    raise "On a non-master branch #{branch}; refusing to tag" unless branch == 'master'
    OctocatalogDiff::Gem.tag
  end

  task 'yank' do
    OctocatalogDiff::Gem.yank
  end

  # These tasks are specific to a GitHub development environment and will likely not be effective
  # in other environments. Specifically this is intended to copy the gem to, and adjust the Gemfile
  # of, a checkout of GitHub's puppet repo in a parallel directory.
  task 'local' do
    Rake::Task['gem:force-build'].invoke
    Rake::Task['gem:localinstall'].invoke
  end

  task 'localinstall' do
    script = File.expand_path('../../puppet/script/octocatalog-diff-update.sh', File.dirname(__FILE__))
    raise "Cannot execute 'localinstall': script '#{script}' is missing" unless File.file?(script)

    # Make sure the gem has been built
    branch = OctocatalogDiff::Gem.branch
    version = OctocatalogDiff::Gem.version
    gemfile = if branch == 'master'
      OctocatalogDiff::Gem::FINAL_GEMFILE
    else
      File.join(OctocatalogDiff::Gem::PKGDIR, "octocatalog-diff-#{version}-#{branch}.gem")
    end
    raise "Cannot execute 'localinstall': gem '#{gemfile}' has not been built" unless File.file?(gemfile)

    # Execute the installation command
    command = [script, gemfile, version].map { |x| Shellwords.escape(x) }.join(' ')
    system command
  end
end
