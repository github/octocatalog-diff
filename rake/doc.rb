require 'erb'
require 'optparse'
require 'rugged'

require_relative '../lib/octocatalog-diff/cli/options'
require_relative '../lib/octocatalog-diff/version'

module OctocatalogDiff
  # A class to contain methods and constants for cleaner code
  class Doc
    include ERB::Util

    attr_accessor :obj

    DOC_TEMPLATE = File.expand_path('./templates/optionsref.erb', File.dirname(__FILE__))
    DOC_NAME = 'doc/optionsref.md'.freeze
    DOC_OUTPUT = File.expand_path("../#{DOC_NAME}", File.dirname(__FILE__))
    CODE_PATH = File.expand_path('../lib/octocatalog-diff/cli/options', File.dirname(__FILE__))

    def file_content(filename)
      @fc ||= {}
      return @fc[filename] if @fc.key?(filename)

      comments = []
      IO.readlines(filename).each do |line|
        next if line =~ /^#\s*@/
        next if line.strip == '# frozen_string_literal: true'
        if line =~ /^#(.+)/
          comments << Regexp.last_match(1).strip
        elsif line =~ /^OctocatalogDiff::/
          break
        end
      end
      @fc[filename] = comments.join("\n")
    end

    def initialize
      OctocatalogDiff::Cli::Options.classes.clear
      options = {}
      @obj = ::OptionParser.new do |parser|
        OctocatalogDiff::Cli::Options.option_classes.each do |klass|
          obj = klass.new
          obj.parse(parser, options)
        end
      end
      @template = File.read(DOC_TEMPLATE)
    end

    def options
      opts = {}
      basedir = File.expand_path('..', File.dirname(__FILE__))
      pat = Regexp.new('^' + Regexp.escape(basedir + '/'))
      @obj.instance_variable_get('@stack').each do |item|
        long = item.instance_variable_get('@long')
        next if long.nil?
        long.each do |_longopt, val|
          filename = val.instance_variable_get('@block').source_location[0]
          next unless filename.start_with?(CODE_PATH + '/')

          arg = val.instance_variable_get('@arg')
          arg.strip! if arg.is_a?(String)

          opt_invoke = val.instance_variable_get('@short') || []
          all_long = val.instance_variable_get('@long').map do |x|
            if x =~ /^--\[no-\](.+)/
              ["--zzzzzzzzzz-#{Regexp.last_match(1)}", "--#{Regexp.last_match(1)}"]
            else
              x
            end
          end
          opt_invoke.concat all_long.flatten.sort.map { |x| x.sub('zzzzzzzzzz', 'no') }

          formatted_options = "<pre><code>#{opt_invoke.uniq.map { |x| x + ' ' + (arg || '') }.join("\n")}</code></pre>"

          lopt = val.instance_variable_get('@long').first

          opts[lopt] = {
            arg: arg || '',
            comment: file_content(filename),
            desc: val.instance_variable_get('@desc').first,
            filename: filename.sub(pat, ''),
            formatted_options: formatted_options
          }
        end
      end
      keys = opts.keys.sort { |a, b| a.sub('[no-]', '').downcase <=> b.sub('[no-]', '').downcase }
      keys.map { |k| opts[k] }
    end

    def render
      ERB.new(@template).result(binding)
    end

    def save
      File.open(DOC_OUTPUT, 'w') { |f| f.write(render.split(/\n/).map(&:rstrip).join("\n")) }
    end
  end
end

namespace :doc do
  task 'build' do
    o = OctocatalogDiff::Doc.new
    o.save
  end
end
