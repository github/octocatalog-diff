# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_parser' do
    @parser_args = ['--parser', '--parser-from', '--parser-to']
    @supported_parsers = %w(default future)

    @parser_args.each do |arg|
      it "should raise error if #{arg} has no argument" do
        expect { run_optparse([arg]) }.to raise_error(OptionParser::MissingArgument)
      end
    end

    @supported_parsers.each do |parser|
      @parser_args.each do |arg|
        it "should accept #{arg} '#{parser}' as argument" do
          result = run_optparse([arg, parser])
          if arg == '--parser'
            expect(result[:parser_from]).to eq(parser.to_sym)
            expect(result[:parser_to]).to eq(parser.to_sym)
          else
            arg_key = arg.sub(/^--/, '').tr('-', '_').to_sym
            expect(result[arg_key]).to eq(parser.to_sym)
          end
        end
      end
    end

    @parser_args.each do |arg|
      it "should reject invalid #{arg}" do
        expect { run_optparse([arg, 'lsdkfslkdaf']) }.to raise_error(ArgumentError)
      end
    end

    it 'should disallow --parser and --parser-from from conflicting' do
      args = ['--parser', 'future', '--parser-from', 'default']
      expect { run_optparse(args) }.to raise_error(ArgumentError)
    end

    it 'should disallow --parser and --parser-to from conflicting' do
      args = ['--parser', 'future', '--parser-to', 'default']
      expect { run_optparse(args) }.to raise_error(ArgumentError)
    end

    it 'should allow --parser and --parser-from to be used together if matching' do
      args = ['--parser', 'default', '--parser-from', 'default']
      result = run_optparse(args)
      expect(result[:parser_from]).to eq(:default)
    end

    it 'should disallow --parser and --parser-to to be used together if matching' do
      args = ['--parser', 'future', '--parser-to', 'future']
      result = run_optparse(args)
      expect(result[:parser_to]).to eq(:future)
    end
  end
end
