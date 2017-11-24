# frozen_string_literal: true

require_relative 'integration_helper'

require 'json'

describe 'fact files by branch, with two fact files' do
  before(:all) do
    @result = OctocatalogDiff::Integration.integration_cli(
      [
        '-n', 'rspec-node.github.net',
        '--bootstrapped-to-dir', OctocatalogDiff::Spec.fixture_path('repos/fact-overrides'),
        '--bootstrapped-from-dir', OctocatalogDiff::Spec.fixture_path('repos/fact-overrides'),
        '--output-format', 'json',
        '--from-fact-file', OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml'),
        '--to-fact-file', OctocatalogDiff::Spec.fixture_path('facts/valid-facts-different-ip.yaml'),
        '--puppet-binary', OctocatalogDiff::Spec::PUPPET_BINARY,
        '--fact-override', 'foofoo=barbar',
        '-d'
      ]
    )
  end

  it 'should exit with status 2' do
    expect(@result.exitcode).to eq(2), @result.stderr
  end

  it 'should contain the correct diffs' do
    parse_result = JSON.parse(@result.stdout)['diff'].map { |x| OctocatalogDiff::Spec.remove_file_and_line(x) }
    expect(parse_result.size).to eq(1)
    expect(parse_result).to include(
      'diff_type' => '~',
      'type' => 'File',
      'title' => '/tmp/ipaddress',
      'structure' => %w(parameters content),
      'old_value' => '10.20.30.40',
      'new_value' => '10.30.50.70'
    )
  end

  it 'should log the correct messages' do
    expect(@result.stderr).to match(/Catalog for . will be built with OctocatalogDiff::Catalog::Computed/)
    expect(@result.stderr).to match(/Override foofoo from nil to "barbar"/)
    expect(@result.stderr).to match(/Diffs computed for rspec-node.github.net/)
  end
end

describe 'fact files by branch, with only a to fact file' do
  before(:all) do
    @tmpdir = Dir.mktmpdir
    ENV['PUPPET_FACT_DIR'] = @tmpdir
    FileUtils.cp OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml'), File.join(@tmpdir, 'rspec-node.github.net.yaml')

    @result = OctocatalogDiff::Integration.integration_cli(
      [
        '-n', 'rspec-node.github.net',
        '--bootstrapped-to-dir', OctocatalogDiff::Spec.fixture_path('repos/fact-overrides'),
        '--bootstrapped-from-dir', OctocatalogDiff::Spec.fixture_path('repos/fact-overrides'),
        '--output-format', 'json',
        '--to-fact-file', OctocatalogDiff::Spec.fixture_path('facts/valid-facts-different-ip.yaml'),
        '--puppet-binary', OctocatalogDiff::Spec::PUPPET_BINARY,
        '--fact-override', 'foofoo=barbar',
        '-d'
      ]
    )
  end

  after(:all) do
    ENV['PUPPET_FACT_DIR'] = nil
    OctocatalogDiff::Spec.clean_up_tmpdir(@tmpdir)
  end

  it 'should exit with status 2' do
    expect(@result.exitcode).to eq(2), @result.stderr
  end

  it 'should contain the correct diffs' do
    parse_result = JSON.parse(@result.stdout)['diff'].map { |x| OctocatalogDiff::Spec.remove_file_and_line(x) }
    expect(parse_result.size).to eq(1)
    expect(parse_result).to include(
      'diff_type' => '~',
      'type' => 'File',
      'title' => '/tmp/ipaddress',
      'structure' => %w(parameters content),
      'old_value' => '10.20.30.40',
      'new_value' => '10.30.50.70'
    )
  end

  it 'should log the correct messages' do
    expect(@result.stderr).to match(/Catalog for . will be built with OctocatalogDiff::Catalog::Computed/)
    expect(@result.stderr).to match(/Override foofoo from nil to "barbar"/)
    expect(@result.stderr).to match(/Diffs computed for rspec-node.github.net/)
  end
end

describe 'fact files by branch, with only a from fact file' do
  before(:all) do
    @tmpdir = Dir.mktmpdir
    ENV['PUPPET_FACT_DIR'] = @tmpdir
    FileUtils.cp OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml'), File.join(@tmpdir, 'rspec-node.github.net.yaml')

    @result = OctocatalogDiff::Integration.integration_cli(
      [
        '-n', 'rspec-node.github.net',
        '--bootstrapped-to-dir', OctocatalogDiff::Spec.fixture_path('repos/fact-overrides'),
        '--bootstrapped-from-dir', OctocatalogDiff::Spec.fixture_path('repos/fact-overrides'),
        '--output-format', 'json',
        '--from-fact-file', OctocatalogDiff::Spec.fixture_path('facts/valid-facts-different-ip.yaml'),
        '--puppet-binary', OctocatalogDiff::Spec::PUPPET_BINARY,
        '--fact-override', 'foofoo=barbar',
        '-d'
      ]
    )
  end

  after(:all) do
    ENV['PUPPET_FACT_DIR'] = nil
    OctocatalogDiff::Spec.clean_up_tmpdir(@tmpdir)
  end

  it 'should exit with status 2' do
    expect(@result.exitcode).to eq(2), @result.stderr
  end

  it 'should contain the correct diffs' do
    parse_result = JSON.parse(@result.stdout)['diff'].map { |x| OctocatalogDiff::Spec.remove_file_and_line(x) }
    expect(parse_result.size).to eq(1)
    expect(parse_result).to include(
      'diff_type' => '~',
      'type' => 'File',
      'title' => '/tmp/ipaddress',
      'structure' => %w(parameters content),
      'new_value' => '10.20.30.40',
      'old_value' => '10.30.50.70'
    )
  end

  it 'should log the correct messages' do
    expect(@result.stderr).to match(/Catalog for . will be built with OctocatalogDiff::Catalog::Computed/)
    expect(@result.stderr).to match(/Override foofoo from nil to "barbar"/)
    expect(@result.stderr).to match(/Diffs computed for rspec-node.github.net/)
  end
end

describe 'fact file from the configuration' do
  before(:all) do
    ENV['PUPPET_FACT_FILE_DIR'] = OctocatalogDiff::Spec.fixture_path('facts')
    @result = OctocatalogDiff::Integration.integration_cli(
      [
        '-n', 'rspec-node.github.net',
        '--bootstrapped-to-dir', OctocatalogDiff::Spec.fixture_path('repos/fact-overrides'),
        '--catalog-only',
        '--puppet-binary', OctocatalogDiff::Spec::PUPPET_BINARY,
        '-d'
      ],
      OctocatalogDiff::Spec.fixture_path('cli-configs/fact-file.rb')
    )
  end

  after(:all) do
    ENV.delete('PUPPET_FACT_FILE_DIR')
  end

  it 'should exit with status 0' do
    expect(@result.exitcode).to eq(0), @result.stderr
  end

  it 'should contain resources generated from the proper fact file' do
    expect(@result.stdout).to match(/"10\.20\.30\.40"/)
  end
end

describe 'fact file overridden on the command line' do
  before(:all) do
    ENV['PUPPET_FACT_FILE_DIR'] = OctocatalogDiff::Spec.fixture_path('facts')
    @result = OctocatalogDiff::Integration.integration_cli(
      [
        '-n', 'rspec-node.github.net',
        '--bootstrapped-to-dir', OctocatalogDiff::Spec.fixture_path('repos/fact-overrides'),
        '--catalog-only',
        '--puppet-binary', OctocatalogDiff::Spec::PUPPET_BINARY,
        '-d',
        '--fact-file', OctocatalogDiff::Spec.fixture_path('facts/valid-facts-different-ip.yaml')
      ],
      OctocatalogDiff::Spec.fixture_path('cli-configs/fact-file.rb')
    )
  end

  after(:all) do
    ENV.delete('PUPPET_FACT_FILE_DIR')
  end

  it 'should exit with status 0' do
    expect(@result.exitcode).to eq(0), @result.stderr
  end

  it 'should contain resources generated from the proper fact file' do
    expect(@result.stdout).to match(/"10\.30\.50\.70"/)
  end
end
