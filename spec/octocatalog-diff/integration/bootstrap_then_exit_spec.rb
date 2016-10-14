require_relative 'integration_helper'

require 'fileutils'

describe 'bootstrap then exit' do
  before(:each) do
    @repo_dir = OctocatalogDiff::Spec.extract_fixture_repo('simple-repo')
    @tmpdir = Dir.mktmpdir
  end

  after(:each) do
    FileUtils.remove_entry_secure @tmpdir if File.directory?(@tmpdir)
    FileUtils.remove_entry_secure @repo_dir if File.directory?(@repo_dir)
  end

  it 'should bootstrap just the to-environment for --bootstrap-then-exit' do
    result = OctocatalogDiff::Integration.integration(
      spec_fact_file: 'facts.yaml',
      output_format: :json,
      argv: [
        '--basedir', File.join(@repo_dir, 'git-repo'),
        '-t', 'test-branch',
        '--bootstrap-then-exit',
        '--bootstrapped-to-dir', File.join(@tmpdir, 'to'),
        '--bootstrap-script', 'script/bootstrap.sh'
      ]
    )
    expect(result[:exitcode]).to eq(0)
    expect(File.directory?(File.join(@tmpdir, 'to'))).to eq(true)
    expect(File.directory?(File.join(@tmpdir, 'from'))).to eq(false)
    expect(File.file?(File.join(@tmpdir, 'to', 'bootstrap_result.yaml'))).to eq(true)
    expect(File.file?(File.join(@tmpdir, 'to', 'modules', 'test', 'manifests', 'init.pp'))).to eq(true)
  end

  it 'should bootstrap just the from-environment for --bootstrap-then-exit' do
    result = OctocatalogDiff::Integration.integration(
      spec_fact_file: 'facts.yaml',
      output_format: :json,
      argv: [
        '--basedir', File.join(@repo_dir, 'git-repo'),
        '-f', 'master',
        '--bootstrap-then-exit',
        '--bootstrapped-from-dir', File.join(@tmpdir, 'from'),
        '--bootstrap-script', 'script/bootstrap.sh'
      ]
    )
    expect(result[:exitcode]).to eq(0)
    expect(File.directory?(File.join(@tmpdir, 'from'))).to eq(true)
    expect(File.directory?(File.join(@tmpdir, 'to'))).to eq(false)
    expect(File.file?(File.join(@tmpdir, 'from', 'bootstrap_result.yaml'))).to eq(true)
    expect(File.file?(File.join(@tmpdir, 'from', 'modules', 'test', 'manifests', 'init.pp'))).to eq(true)
  end

  it 'should bootstrap both environments for --bootstrap-then-exit' do
    result = OctocatalogDiff::Integration.integration(
      spec_fact_file: 'facts.yaml',
      output_format: :json,
      argv: [
        '--basedir', File.join(@repo_dir, 'git-repo'),
        '-f', 'master',
        '-t', 'test-branch',
        '--bootstrap-then-exit',
        '--bootstrapped-from-dir', File.join(@tmpdir, 'from'),
        '--bootstrapped-to-dir', File.join(@tmpdir, 'to'),
        '--bootstrap-script', 'script/bootstrap.sh'
      ]
    )
    expect(result[:exitcode]).to eq(0)
    expect(File.directory?(File.join(@tmpdir, 'from'))).to eq(true)
    expect(File.directory?(File.join(@tmpdir, 'to'))).to eq(true)
    expect(File.file?(File.join(@tmpdir, 'from', 'bootstrap_result.yaml'))).to eq(true)
    expect(File.file?(File.join(@tmpdir, 'from', 'modules', 'test', 'manifests', 'init.pp'))).to eq(true)
    expect(File.file?(File.join(@tmpdir, 'to', 'bootstrap_result.yaml'))).to eq(true)
    expect(File.file?(File.join(@tmpdir, 'to', 'modules', 'test', 'manifests', 'init.pp'))).to eq(true)
  end

  it 'should raise an error when it cannot create a bootstrapped directory' do
    result = OctocatalogDiff::Integration.integration(
      spec_fact_file: 'facts.yaml',
      output_format: :json,
      argv: [
        '--basedir', File.join(@repo_dir, 'git-repo'),
        '-f', 'master',
        '--bootstrap-then-exit',
        '--bootstrapped-from-dir', File.join(@tmpdir, 'from', 'level', 'blah')
      ]
    )
    expect(result[:exitcode]).to eq(-1)
    expect(result[:exception].class.to_s).to eq('Errno::ENOENT')
    expect(result[:exception].message).to match(%r{from/level/blah$})
  end

  it 'should return with exit(1) when it cannot check out a branch' do
    result = OctocatalogDiff::Integration.integration(
      spec_fact_file: 'facts.yaml',
      output_format: :json,
      argv: [
        '--basedir', File.join(@repo_dir, 'git-repo'),
        '-f', 'asdfadsfasdfds',
        '--bootstrap-then-exit',
        '--bootstrapped-from-dir', File.join(@tmpdir, 'from')
      ]
    )
    expect(result[:exitcode]).to eq(1)
    expect(result[:logs]).to match(/FATAL -- : --bootstrap-then-exit error: bootstrap failed/)
  end
end
