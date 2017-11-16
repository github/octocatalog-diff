require 'fileutils'
require 'open3'
require 'rspec/core/rake_task'
require 'shellwords'
require 'tempfile'

# Define the tasks
if defined?(RSpec)
  namespace :coverage do
    task 'all' do
      ENV['COVERAGE'] = 'true'
      Rake::Task['spec:all'].invoke
    end

    task 'integration' do
      ENV['COVERAGE'] = 'true'
      Rake::Task['spec:integration'].invoke
    end

    task 'spec' do
      ENV['COVERAGE'] = 'true'
      Rake::Task['spec:spec'].invoke
    end
  end

  namespace :spec do
    PARALLEL_CONFIG = File.expand_path('../.rspec_parallel', File.dirname(__FILE__))
    def write_config(filename)
      File.open(PARALLEL_CONFIG, 'w') do |f|
        f.write "--format progress\n"
        f.write "--format ParallelTests::RSpec::RuntimeLogger --out #{filename}\n"
        f.close
      end
    end

    task 'all' do
      abort('Puppet binary missing. Please run script/bootstrap!') unless File.file?(PUPPET_BINARY)
      paths = 'spec/octocatalog-diff/integration spec/octocatalog-diff/tests'
      logfile = File.expand_path('../.parallel_runtime_rspec.log', File.dirname(__FILE__))
      begin
        File.open(logfile, 'w') do |f|
          %w(integration tests).each do |file|
            path = File.expand_path("../.parallel_runtime_#{file}.log", File.dirname(__FILE__))
            next unless File.file?(path)
            f.write File.read(path)
          end
        end
        write_config(logfile)
        runtime_log = TEST_COMMAND =~ /parallel/ ? '--runtime-log .parallel_runtime_rspec.log' : ''
        cmd = "bundle exec #{TEST_COMMAND} #{runtime_log} #{paths} 2>/dev/null"
        abort unless system(cmd)
        f1 = File.open(File.expand_path('../.parallel_runtime_integration.log', File.dirname(__FILE__)), 'w')
        f2 = File.open(File.expand_path('../.parallel_runtime_tests.log', File.dirname(__FILE__)), 'w')
        File.read(logfile).split(/\n/).each do |line|
          if line =~ %r{^spec/octocatalog-diff/tests/}
            f2.write "#{line}\n"
          elsif line =~ %r{^spec/octocatalog-diff/integration/}
            f1.write "#{line}\n"
          end
        end
        f1.close
        f2.close
      ensure
        FileUtils.rm PARALLEL_CONFIG if File.file?(PARALLEL_CONFIG)
        FileUtils.rm File.expand_path('../.parallel_runtime_rspec.log', File.dirname(__FILE__))
      end
    end

    task 'integration' do
      abort('Puppet binary missing. Please run script/bootstrap!') unless File.file?(PUPPET_BINARY)
      begin
        write_config('.parallel_runtime_integration.log')
        runtime_log = TEST_COMMAND =~ /parallel/ ? '--runtime-log .parallel_runtime_integration.log' : ''
        cmd = "bundle exec #{TEST_COMMAND} #{runtime_log} spec/octocatalog-diff/integration 2>/dev/null"
        abort unless system(cmd)
      ensure
        FileUtils.rm PARALLEL_CONFIG if File.file?(PARALLEL_CONFIG)
      end
    end

    task 'spec' do
      abort('Puppet binary missing. Please run script/bootstrap!') unless File.file?(PUPPET_BINARY)
      begin
        write_config('.parallel_runtime_tests.log')
        runtime_log = TEST_COMMAND =~ /parallel/ ? '--runtime-log .parallel_runtime_tests.log' : ''
        cmd = "bundle exec #{TEST_COMMAND} #{runtime_log} spec/octocatalog-diff/tests 2>/dev/null"
        abort unless system(cmd)
      ensure
        FileUtils.rm PARALLEL_CONFIG if File.file?(PARALLEL_CONFIG)
      end
    end
  end
end
