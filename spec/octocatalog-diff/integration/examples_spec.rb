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
  let(:script) { File.expand_path('../../../examples/api/v1/catalog-builder-local-files.rb', File.dirname(__FILE__)) }
  let(:ls_l) { Open3.capture2e("ls -l '#{script}'").first }

  it 'should exist' do
    expect(File.file?(script)).to eq(true), ls_l
  end

  context 'executing' do
    before(:each) do
      @stdout_obj = StringIO.new
      @old_stdout = $stdout
      $stdout = @stdout_obj
    end

    after(:each) do
      $stdout = @old_stdout
    end

    it 'should compile and run' do
      load script
      output = @stdout_obj.string.split("\n")
      expect(output).to include('Object returned from OctocatalogDiff::API::V1.catalog is: OctocatalogDiff::API::V1::Catalog')
      expect(output).to include('The catalog is valid.')
      expect(output).to include('The catalog was built using OctocatalogDiff::Catalog::Computed')
      expect(output).to include('- System::User - bob')
      expect(output).to include('The resources are equal!')
    end
  end
end
