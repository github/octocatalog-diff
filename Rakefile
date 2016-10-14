require 'rake'
require 'fileutils'

Dir.chdir File.dirname(__FILE__)

load 'rake/common.rb'
Dir['rake/*.rb'].each { |f| load f unless f =~ %r{/common.rb} }

task gem: ['gem:build', 'gem:tag', 'gem:push']

task rubocop: 'rubocop:all'
task style: :rubocop

task spec: 'spec:all'
task test: :spec

task default: :spec
