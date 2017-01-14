# frozen_string_literal: true

require_relative '../tests/spec_helper'

require 'open3'
require 'stringio'

describe 'examples/octocatalog-diff.cfg.rb' do
  let(:script) { File.expand_path('../../../examples/octocatalog-diff.cfg.rb', File.dirname(__FILE__)) }
  let(:ls_l) { Open3.capture2e("ls -l '#{script}'").first }

  it 'should exist' do
    expect(File.file?(script)).to eq(true), ls_l
  end

  it 'should not raise errors when loaded' do
    load script
  end

  it 'should create OctocatalogDiff::Config namespace and .config method' do
    k = Kernel.const_get('OctocatalogDiff::Config')
    expect(k.to_s).to eq('OctocatalogDiff::Config')
  end

  it 'should return a hash from the .config method' do
    result = OctocatalogDiff::Config.config
    expect(result).to be_a_kind_of(Hash)
  end
end

describe 'examples/api/v1/catalog-builder-local-files.rb' do
  before(:all) do
    @script = File.expand_path('../../../examples/api/v1/catalog-builder-local-files.rb', File.dirname(__FILE__))
  end

  it 'should exist' do
    ls_l = Open3.capture2e("ls -l '#{@script}'").first
    expect(File.file?(@script)).to eq(true), ls_l
  end

  context 'executing' do
    before(:all) do
      @stdout, @stderr, @exitcode = Open3.capture3(@script)
    end

    it 'should run without error' do
      expect(@exitcode.exitstatus).to eq(0)
    end

    it 'should print the expected output' do
      output = @stdout.split("\n")
      expect(output).to include('Object returned from OctocatalogDiff::API::V1.catalog is: OctocatalogDiff::API::V1::Catalog')
      expect(output).to include('The catalog is valid.')
      expect(output).to include('The catalog was built using OctocatalogDiff::Catalog::Computed')
      expect(output).to include('- System::User - bob')
      expect(output).to include('The resources are equal!')
    end

    it 'should not output to STDERR' do
      expect(@stderr).to eq('')
    end
  end
end

describe 'examples/api/v1/catalog-diff-local-files.rb' do
  before(:all) do
    @script = File.expand_path('../../../examples/api/v1/catalog-diff-local-files.rb', File.dirname(__FILE__))
  end

  it 'should exist' do
    ls_l = Open3.capture2e("ls -l '#{@script}'").first
    expect(File.file?(@script)).to eq(true), ls_l
  end

  context 'executing' do
    before(:all) do
      @stdout, @stderr, @exitcode = Open3.capture3(@script)
    end

    it 'should run without error' do
      expect(@exitcode.exitstatus).to eq(0)
    end

    it 'should print the expected output' do
      output = @stdout.split("\n")
      expect(output).to include('Object returned from OctocatalogDiff::API::V1.catalog_diff is: OpenStruct')
      expect(output).to include('The keys are: diffs, from, to')
      expect(output).to include('There are 36 diffs reported here')
    end

    it 'should not output to STDERR' do
      expect(@stderr).to eq('')
    end
  end
end

describe 'examples/api/v1/catalog-diff-git-repo.rb' do
  before(:all) do
    @script = File.expand_path('../../../examples/api/v1/catalog-diff-git-repo.rb', File.dirname(__FILE__))
  end

  it 'should exist' do
    ls_l = Open3.capture2e("ls -l '#{@script}'").first
    expect(File.file?(@script)).to eq(true), ls_l
  end

  context 'executing' do
    before(:all) do
      @stdout, @stderr, @exitcode = Open3.capture3(@script)
    end

    it 'should run without error' do
      expect(@exitcode.exitstatus).to eq(0)
    end

    it 'should print the expected output' do
      output = @stdout.split("\n")
      expect(output).to include('Here is the directory containing the git repository.')
      expect(@stdout).to match(/DEBUG -- : Compiling catalogs for rspec-node.github.net/)
      expect(@stdout).to match(/Entering catdiff; catalog sizes: 6, 9/)
      expect(output).to include('The from-catalog has 6 resources')
      expect(output).to include('The to-catalog has 9 resources')
      expect(output).to include('There are 6 differences')
      expect(output).to include('Added a File resource called /tmp/bar!')
      expect(output).to include('Changed the File resource /tmp/foo attribute parameters::group')
    end

    it 'should not output to STDERR' do
      expect(@stderr).to eq('')
    end
  end
end
