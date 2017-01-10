# frozen_string_literal: true

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

  # Test the file comparison feature itself here in its various iterations.
  describe 'file comparison feature' do
    before(:each) do
      @from_dir = Dir.mktmpdir
      FileUtils.cp_r OctocatalogDiff::Spec.fixture_path('repos/modulepath'), @from_dir

      @to_dir = Dir.mktmpdir
      FileUtils.cp_r OctocatalogDiff::Spec.fixture_path('repos/modulepath'), @to_dir

      file1 = File.join(@to_dir, 'modulepath', 'modules', 'modulestest', 'files', 'tmp', 'modulestest')
      File.open(file1, 'w') { |f| f.write("New content of modulestest\n") }

      file2 = File.join(@to_dir, 'modulepath', 'site', 'sitetest', 'files', 'tmp', 'sitetest')
      File.open(file2, 'w') { |f| f.write("New content of sitetest\n") }
    end

    after(:each) do
      OctocatalogDiff::Spec.clean_up_tmpdir(@from_dir)
      OctocatalogDiff::Spec.clean_up_tmpdir(@to_dir)
    end

    let(:module_answer) do
      {
        diff_type: '~',
        type: 'File',
        title: '/tmp/modulestest',
        structure: %w(parameters content),
        old_value: "Modules Test\n",
        new_value: "New content of modulestest\n"
      }
    end

    let(:site_answer) do
      {
        diff_type: '~',
        type: 'File',
        title: '/tmp/sitetest',
        structure: %w(parameters content),
        old_value: "Site Test\n",
        new_value: "New content of sitetest\n"
      }
    end

    context 'with environment.conf' do
      # The environment.conf is a fixture within the repository so there is no need
      # to create it or manipulate it.
      before(:each) do
        @result = OctocatalogDiff::Integration.integration(
          spec_fact_file: 'facts.yaml',
          argv: [
            '-n', 'rspec-node.github.net',
            '--bootstrapped-from-dir', File.join(@from_dir, 'modulepath'),
            '--bootstrapped-to-dir', File.join(@to_dir, 'modulepath')
          ]
        )
      end

      it 'should compile catalogs and compute differences' do
        expect(@result[:exitcode]).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
        expect(@result[:diffs]).to be_a_kind_of(Array)
        expect(@result[:diffs].size).to eq(2)
        expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], module_answer)).to eq(true)
        expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], site_answer)).to eq(true)
      end
    end

    context 'without environment.conf in one directory' do
      before(:each) do
        FileUtils.rm_f File.join(@from_dir, 'modulepath', 'environment.conf')
        FileUtils.mv File.join(@from_dir, 'modulepath', 'site', 'sitetest'), File.join(@from_dir, 'modulepath', 'modules')
        @result = OctocatalogDiff::Integration.integration(
          spec_fact_file: 'facts.yaml',
          argv: [
            '-n', 'rspec-node.github.net',
            '--bootstrapped-from-dir', File.join(@from_dir, 'modulepath'),
            '--bootstrapped-to-dir', File.join(@to_dir, 'modulepath')
          ]
        )
      end

      it 'should compile catalogs and compute differences' do
        expect(@result[:exitcode]).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
        expect(@result[:diffs]).to be_a_kind_of(Array)
        expect(@result[:diffs].size).to eq(2)
        expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], module_answer)).to eq(true)
        expect(OctocatalogDiff::Spec.diff_match?(@result[:diffs], site_answer)).to eq(true)
      end
    end
  end
end
