require_relative 'integration_helper'

describe 'convert file resources' do
  context 'with option enabled' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_fact_file: 'facts.yaml',
        spec_repo_old: 'convert-resources/old',
        spec_repo_new: 'convert-resources/new',
        argv: [
          '-n', 'rspec-node.github.net',
          '--compare-file-text'
        ]
      )
    end

    it 'should compile the catalog' do
      expect(@result[:exitcode]).not_to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
      expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
      expect(@result[:diffs]).to be_a_kind_of(Array)
    end

    it 'should contain the correct number of diffs' do
      expect(@result[:diffs].size).to eq(3), @result[:diffs].inspect
    end

    it 'should contain /tmp/foo1' do
      answer = ['~', "File\f/tmp/foo1\fparameters\fcontent", "content of foo-old\n", "content of foo-new\n"]
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(@result[:diffs], answer)).to eq(true)
    end

    it 'should contain /tmp/binary1' do
      answer = [
        '~',
        "File\f/tmp/binary1\fparameters\fcontent",
        '{md5}e0897d525d5d600a037622b62fc99a4c',
        '{md5}97918b387001eb04ae7cb20b13e07f43'
      ]
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(@result[:diffs], answer)).to eq(true)
    end

    it 'should contain /tmp/bar2' do
      answer = ['~', "File\f/tmp/bar2\fparameters\fcontent", "content of bar\n", "content of new-bar\n"]
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(@result[:diffs], answer)).to eq(true)
    end
  end

  context 'with option disabled' do
    before(:all) do
      @result = OctocatalogDiff::Integration.integration(
        spec_fact_file: 'facts.yaml',
        spec_repo_old: 'convert-resources/old',
        spec_repo_new: 'convert-resources/new',
        argv: [
          '-n', 'rspec-node.github.net',
          '--no-compare-file-text'
        ]
      )
    end

    it 'should compile the catalog' do
      expect(@result[:exitcode]).not_to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
      expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
      expect(@result[:diffs]).to be_a_kind_of(Array)
    end

    it 'should contain the correct number of diffs' do
      expect(@result[:diffs].size).to eq(8)
    end

    it 'should contain /tmp/binary1' do
      answer = [
        '~',
        "File\f/tmp/binary1\fparameters\fsource",
        'puppet:///modules/test/binary-old',
        'puppet:///modules/test/binary-new'
      ]
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(@result[:diffs], answer)).to eq(true)
    end

    it 'should contain /tmp/binary3' do
      answer = [
        '~',
        "File\f/tmp/binary3\fparameters\fsource",
        'puppet:///modules/test/binary-old',
        'puppet:///modules/test/binary-old2'
      ]
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(@result[:diffs], answer)).to eq(true)
    end

    it 'should contain /tmp/foo1' do
      answer = ['~', "File\f/tmp/foo1\fparameters\fsource", 'puppet:///modules/test/foo-old', 'puppet:///modules/test/foo-new']
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(@result[:diffs], answer)).to eq(true)
    end

    it 'should contain /tmp/bar content' do
      answer = ['!', "File\f/tmp/bar\fparameters\fcontent", nil, "content of bar\n"]
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(@result[:diffs], answer)).to eq(true)
    end

    it 'should contain /tmp/bar source' do
      answer = ['!', "File\f/tmp/bar\fparameters\fsource", 'puppet:///modules/test/bar-old', nil]
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(@result[:diffs], answer)).to eq(true)
    end
  end

  context 'with broken repo' do
    it 'should fail' do
      result = OctocatalogDiff::Integration.integration(
        spec_fact_file: 'facts.yaml',
        spec_repo_old: 'convert-resources/old',
        spec_repo_new: 'convert-resources/broken',
        argv: [
          '-n', 'rspec-node.github.net',
          '--compare-file-text'
        ]
      )
      expect(result[:exitcode]).to eq(-1)
      expect(result[:exception]).to be_a_kind_of(OctocatalogDiff::CatalogDiff::Cli::Catalogs::CatalogError)
      expect(result[:exception].message).to match(/failed to compile with Errno::ENOENT/)
      expect(result[:exception].message).to match(%r{Unable to resolve 'puppet:///modules/test/foo-new'})
    end
  end
end
