# frozen_string_literal: true

require_relative '../spec_helper'

require OctocatalogDiff::Spec.require_path('/cli/options')

# We actually call the top-level "parse_options" which will call all of
# the methods. This test therefore ensures that (a) parse_options contains
# the call to the individual method, and (b) the individual method works.
# @param argv [Array] Argument values (simulated command line)
# @param options_in [Hash] Default options
# @return [Hash] Parsed options
def run_optparse(argv = [], options_in = {})
  OctocatalogDiff::Cli::Options.parse_options(argv, options_in)
end

# Many boolean command line flags have very similar tests. Specifying --option sets
# something to true; specifying --no-option sets that same something to false. This
# is a shortcut to eliminating repetitive code.
# @param cli_flag [String] The CLI flag
# @param key [Symbol] Key within options that is set to true or false
RSpec.shared_examples 'true/false option' do |cli_flag, key|
  it "should set options[:#{key}] to true when --#{cli_flag} is set" do
    result = run_optparse(["--#{cli_flag}"])
    expect(result[key]).to eq(true)
  end

  it "should set options[:#{key}] to false when --no-#{cli_flag} is set" do
    result = run_optparse(["--no-#{cli_flag}"])
    expect(result[key]).to eq(false)
  end
end

# Some options can be set globally or per branch. This is a shortcut to eliminating
# repetitive testing code.
# @param cli_flag [String] The CLI flag
# @param key [Symbol] Key within options that is set to true or false
RSpec.shared_examples 'global string option' do |cli_flag, key|
  let(:answer_a) { 'Answer-a' }
  let(:answer_b) { 'Answer-b' }

  it "should set options[:from_#{key}] and options[:to_#{key}] when --#{cli_flag} is set" do
    result = run_optparse(["--#{cli_flag}", 'Answer-a'])
    expect(result["from_#{key}".to_sym]).to eq(answer_a)
    expect(result["to_#{key}".to_sym]).to eq(answer_a)
  end

  it 'should use specific values and global values' do
    result = run_optparse(["--#{cli_flag}", 'Answer-a', "--from-#{cli_flag}", 'Answer-b'])
    expect(result["from_#{key}".to_sym]).to eq(answer_b)
    expect(result["to_#{key}".to_sym]).to eq(answer_a)
  end

  it 'should not set options when no default is specified' do
    result = run_optparse(["--from-#{cli_flag}", 'Answer-a'])
    expect(result["from_#{key}".to_sym]).to eq(answer_a)
    expect(result.key?("to_#{key}".to_sym)).to be(false)
  end
end

# Some options can be set globally or per branch. This is a shortcut to eliminating
# repetitive testing code.
# @param cli_flag [String] The CLI flag
# @param key [Symbol] Key within options that is set to true or false
RSpec.shared_examples 'global array option' do |cli_flag, key|
  let(:answer_a) { 'Answer-a' }
  let(:answer_b) { 'Answer-b' }

  it "should set options[:from_#{key}] and options[:to_#{key}] when --#{cli_flag} is set" do
    result = run_optparse(["--#{cli_flag}", 'Answer-a'])
    expect(result["from_#{key}".to_sym]).to eq([answer_a])
    expect(result["to_#{key}".to_sym]).to eq([answer_a])
  end

  it 'should use specific values and global values' do
    result = run_optparse(["--#{cli_flag}", 'Answer-a', "--from-#{cli_flag}", 'Answer-b'])
    expect(result["from_#{key}".to_sym]).to eq([answer_a, answer_b])
    expect(result["to_#{key}".to_sym]).to eq([answer_a])
  end

  it 'should not set options when no default is specified' do
    result = run_optparse(["--from-#{cli_flag}", 'Answer-a'])
    expect(result["from_#{key}".to_sym]).to eq([answer_a])
    expect(result.key?("to_#{key}".to_sym)).to be(false)
  end
end

# Some options can be set globally or per branch. This is a shortcut to eliminating
# repetitive testing code.
# @param cli_flag [String] The CLI flag
# @param key [Symbol] Key within options that is set to true or false
RSpec.shared_examples 'global true/false option' do |cli_flag, key|
  it "should set options[:from_#{key}] and options[:to_#{key}] when --#{cli_flag} is set" do
    result = run_optparse(["--#{cli_flag}"])
    expect(result["from_#{key}".to_sym]).to eq(true)
    expect(result["to_#{key}".to_sym]).to eq(true)
  end

  it "should set options[:from_#{key}] and options[:to_#{key}] when --no-#{cli_flag} is set" do
    result = run_optparse(["--no-#{cli_flag}"])
    expect(result["from_#{key}".to_sym]).to eq(false)
    expect(result["to_#{key}".to_sym]).to eq(false)
  end

  it 'should use specific values and global values' do
    result = run_optparse(["--#{cli_flag}", "--no-from-#{cli_flag}"])
    expect(result["from_#{key}".to_sym]).to eq(false)
    expect(result["to_#{key}".to_sym]).to eq(true)
  end

  it 'should not set options when no default is specified' do
    result = run_optparse(["--to-#{cli_flag}"])
    expect(result["to_#{key}".to_sym]).to be(true)
    expect(result.key?("from_#{key}".to_sym)).to be(false)
  end
end
