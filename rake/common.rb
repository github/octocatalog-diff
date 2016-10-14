# Constants
BASEDIR = File.expand_path('..', File.dirname(__FILE__)).freeze
PUPPET_BINARY = File.join(BASEDIR, 'bin', 'puppet').freeze
TEST_COMMAND = "parallel_rspec --suffix '_spec.rb$'".freeze
