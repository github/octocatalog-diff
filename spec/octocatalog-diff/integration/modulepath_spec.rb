require_relative 'integration_helper'
require OctocatalogDiff::Spec.require_path('/catalog')

describe 'multiple module paths' do
  # Make sure the catalog compiles correctly, without using any of the file
  # conversion resources. If the catalog doesn't compile correctly this could
  # indicate a problem that lies somewhere other than the comparison code.
  describe 'catalog only' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_fact_file: 'facts.yaml',
        spec_repo: 'modulepath',
        argv: [
          '--catalog-only',
          '-n', 'rspec-node.github.net',
          '--no-compare-file-text'
        ]
      )
      @catalog = OctocatalogDiff::Catalog.new(
        backend: :json,
        json: @result[:output]
      )
    end

    it 'should compile' do
      expect(@result[:exitcode]).not_to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
    end

    it 'should be a valid catalog' do
      pending 'catalog failed to compile' if @result[:exitcode] == -1
      expect(@catalog.valid?).to eq(true)
    end

    it 'should have expected resources in catalog' do
      pending 'catalog was invalid' unless @catalog.valid?
      expect(@catalog.resources).to be_a_kind_of(Array)

      mf = @catalog.resource(type: 'File', title: '/tmp/modulestest')
      expect(mf).to be_a_kind_of(Hash)
      expect(mf['parameters']).to eq('source' => 'puppet:///modules/modulestest/tmp/modulestest')

      sf = @catalog.resource(type: 'File', title: '/tmp/sitetest')
      expect(sf).to be_a_kind_of(Hash)
      expect(sf['parameters']).to eq('source' => 'puppet:///modules/sitetest/tmp/sitetest')
    end
  end
end
