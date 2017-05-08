# frozen_string_literal: true

require_relative 'integration_helper'

require 'fileutils'

describe 'cached master directory' do
  context 'with default cached branch origin/master' do
    before(:all) do
      @repo_dir = OctocatalogDiff::Spec.extract_fixture_repo('simple-repo')
      @cached_master_dir = Dir.mktmpdir
      @result = OctocatalogDiff::Integration.integration(
        spec_fact_file: 'facts.yaml',
        output_format: :json,
        argv: [
          '--basedir', File.join(@repo_dir, 'git-repo'),
          '--hiera-config', 'config/hiera.yaml',
          '--hiera-path-strip', '/var/lib/puppet',
          '--enc', 'config/enc.sh',
          '-f', 'master',
          '-t', 'test-branch',
          '--cached-master-dir', @cached_master_dir,
          '-n', 'rspec-node.github.net'
        ]
      )
    end

    after(:all) do
      FileUtils.remove_entry_secure @cached_master_dir if File.directory?(@cached_master_dir)
      FileUtils.remove_entry_secure @repo_dir if File.directory?(@repo_dir)
    end

    it 'should compile the catalog' do
      expect(@result[:exitcode]).not_to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
      expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
      expect(@result[:diffs]).to be_a_kind_of(Array)
    end

    # origin/master is the default and 'master' != 'origin/master'
    it 'should not cache the master directory' do
      expect(Dir.glob("#{@cached_master_dir}/**").size).to eq(0)
    end

    it 'should produce the expected catalog-diffs' do
      expect(@result[:diffs].size).to eq(5)
    end
  end

  context 'with non-default cached branch master' do
    before(:all) do
      @repo_dir = OctocatalogDiff::Spec.extract_fixture_repo('simple-repo')
      @cached_master_dir = Dir.mktmpdir
      @result = OctocatalogDiff::Integration.integration(
        spec_fact_file: 'facts.yaml',
        output_format: :json,
        argv: [
          '--basedir', File.join(@repo_dir, 'git-repo'),
          '--hiera-config', 'config/hiera.yaml',
          '--hiera-path-strip', '/var/lib/puppet',
          '--enc', 'config/enc.sh',
          '-f', 'master',
          '-t', 'test-branch',
          '--cached-master-dir', @cached_master_dir,
          '--master-cache-branch', 'master',
          '-n', 'rspec-node.github.net'
        ]
      )
    end

    after(:all) do
      FileUtils.remove_entry_secure @cached_master_dir if File.directory?(@cached_master_dir)
      FileUtils.remove_entry_secure @repo_dir if File.directory?(@repo_dir)
    end

    it 'should compile the catalog' do
      expect(@result[:exitcode]).not_to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
      expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
      expect(@result[:diffs]).to be_a_kind_of(Array)
    end

    it 'should produce the expected catalog-diffs' do
      expect(@result[:diffs].size).to eq(5)
    end

    it 'should produce log messages indicating the dirctory is being cached' do
      expect(@result[:logs]).to match(/Begin bootstrap cached master directory/)
      expect(@result[:logs]).to match(/Success bootstrap cached master directory/)
      expect(@result[:logs]).to match(/Cached master directory bootstrapped to 948b3874f5af7f91a5f370e306731fec048fa62e/)
      expect(@result[:logs]).to match(/Cached master catalog for rspec-node.github.net/)
    end

    it 'should store the SHA in the cached directory' do
      sha_file = File.join(@cached_master_dir, '.catalog-diff-master.sha')
      expect(File.file?(sha_file)).to eq(true), `ls -lRa "#{@cached_master_dir}"`
      expect(File.read(sha_file)).to eq('948b3874f5af7f91a5f370e306731fec048fa62e')
    end

    it 'should store the catalog in the cached directory' do
      expected_file = File.join(@cached_master_dir, '.catalogs', 'rspec-node.github.net.json')
      expect(File.file?(expected_file)).to eq(true), `ls -lRa "#{@cached_master_dir}"`
    end

    it 'should have written content into the cache directory' do
      expect(File.file?(File.join(@cached_master_dir, 'config', 'hiera.yaml'))).to eq(true)
      expect(File.file?(File.join(@cached_master_dir, 'hieradata', 'common.yaml'))).to eq(true)
      expect(File.file?(File.join(@cached_master_dir, 'manifests', 'site.pp'))).to eq(true)
    end

    it 'should reuse the cached catalog during a second compile' do
      result = OctocatalogDiff::Integration.integration(
        spec_fact_file: 'facts.yaml',
        output_format: :json,
        argv: [
          '--basedir', File.join(@repo_dir, 'git-repo'),
          '--hiera-config', 'config/hiera.yaml',
          '--hiera-path-strip', '/var/lib/puppet',
          '--enc', 'config/enc.sh',
          '-f', 'master',
          '-t', 'test-branch',
          '--cached-master-dir', @cached_master_dir,
          '--master-cache-branch', 'master',
          '-n', 'rspec-node.github.net'
        ]
      )

      # Make sure the catalog compiled
      expect(result[:exitcode]).not_to eq(-1), OctocatalogDiff::Integration.format_exception(result)
      expect(result[:exitcode]).to eq(2), "Runtime error: #{result[:logs]}"
      expect(result[:diffs]).to be_a_kind_of(Array)
      expect(result[:diffs].size).to eq(5)

      # Examine log messages to ensure that cached catalog was used
      expect(result[:logs]).to match(/Cached master dir: bootstrapped=948b3\w+; current=948b3874f5af7f91a5f370e30\w+/)
      expect(result[:logs]).to match(/Setting --bootstrapped-from-dir=/)
      expect(result[:logs]).to match(%r{Setting --from-catalog=.*/.catalogs/rspec-node.github.net.json})
      expect(result[:logs]).to match(/Initialized OctocatalogDiff::Catalog::JSON for from-catalog/)
      expect(result[:logs]).to match(/Initialized OctocatalogDiff::Catalog::Computed for to-catalog/)
    end

    it 'should error when the safe-to-delete is not set' do
      # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      # !!! DEPENDS ON PRIOR TEST !!!
      # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

      # Rewrite the SHA file
      sha_file = File.join(@cached_master_dir, '.catalog-diff-master.sha')
      File.open(sha_file, 'w') { |f| f.write('asdlfkjadfsklj') }

      # Run it
      result = OctocatalogDiff::Integration.integration(
        spec_fact_file: 'facts.yaml',
        output_format: :json,
        argv: [
          '--basedir', File.join(@repo_dir, 'git-repo'),
          '--hiera-config', 'config/hiera.yaml',
          '--hiera-path-strip', '/var/lib/puppet',
          '--enc', 'config/enc.sh',
          '-f', 'master',
          '-t', 'test-branch',
          '--cached-master-dir', @cached_master_dir,
          '--master-cache-branch', 'master',
          '-n', 'rspec-node.github.net'
        ]
      )

      # Make sure it errored
      expect(result[:exitcode]).to eq(-1)
      expect(result[:exception]).to be_a_kind_of(Errno::EEXIST)
      expect(result[:exception].message).to match(/To proceed, .* needs to be deleted, so it can be re-created/)
      expect(result[:logs]).to match(/bootstrapped=asdlfkjadfsklj; current=948b3874f5af7f91a5f370e306731fec048fa62e/)
    end

    it 'should rebuild the cached catalog when the sha changes' do
      # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      # !!! DEPENDS ON PRIOR TEST !!!
      # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

      # Make sure this exists before we start
      catalog_file = File.join(@cached_master_dir, '.catalogs', 'rspec-node.github.net.json')
      expect(File.file?(catalog_file)).to eq(true)
      old_timestamp = File.mtime(catalog_file)

      # Put another file in the directory, to make sure it's removed
      File.open(File.join(@cached_master_dir, '.flag'), 'w') { |f| f.write('foo') }

      # Compile catalog again
      result = OctocatalogDiff::Integration.integration(
        spec_fact_file: 'facts.yaml',
        output_format: :json,
        argv: [
          '--basedir', File.join(@repo_dir, 'git-repo'),
          '--hiera-config', 'config/hiera.yaml',
          '--hiera-path-strip', '/var/lib/puppet',
          '--enc', 'config/enc.sh',
          '-f', 'master',
          '-t', 'test-branch',
          '--cached-master-dir', @cached_master_dir,
          '--safe-to-delete-cached-master-dir', @cached_master_dir,
          '--master-cache-branch', 'master',
          '-n', 'rspec-node.github.net',
          '--no-parallel'
        ]
      )

      # Make sure the catalog compiled
      expect(result[:exitcode]).not_to eq(-1), OctocatalogDiff::Integration.format_exception(result)
      expect(result[:exitcode]).to eq(2), "Runtime error: #{result[:logs]}"
      expect(result[:diffs]).to be_a_kind_of(Array)
      expect(result[:diffs].size).to eq(5)

      # Examine log messages to ensure that cached catalog was not used
      expect(result[:logs]).to match(/Cached master dir: bootstrapped=asdlfkjadfsklj; current=948b3874f5af7/)
      expect(result[:logs]).not_to match(%r{Setting --from-catalog=.*/.catalogs/rspec-node.github.net.json})
      expect(result[:logs]).to match(/Success build_catalog for test-branch/)
      expect(result[:logs]).to match(/Success build_catalog for master/)
      expect(result[:logs]).to match(/Cached master directory bootstrapped to 948b3874f5af7f91a5f370e306731fec048fa62e/)

      # Make sure the flag file got removed
      expect(File.file?(File.join(@cached_master_dir, '.flag'))).to eq(false)

      # Make sure the new catalog got cached
      expect(File.file?(catalog_file)).to eq(true)

      # Make sure the timestamp on the cached catalog got updated
      expect(File.mtime(catalog_file)).not_to eq(old_timestamp)
    end
  end
end
