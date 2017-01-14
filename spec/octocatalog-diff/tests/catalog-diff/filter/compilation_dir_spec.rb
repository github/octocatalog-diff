# frozen_string_literal: true

require_relative '../../spec_helper'
require OctocatalogDiff::Spec.require_path('/catalog')
require OctocatalogDiff::Spec.require_path('/catalog-diff/filter/compilation_dir')
require OctocatalogDiff::Spec.require_path('/cli/diffs')

describe OctocatalogDiff::CatalogDiff::Filter::CompilationDir do
  before(:all) do
    @cat_compilation_dir_1 = OctocatalogDiff::Catalog.new(
      node: 'my.rspec.node',
      basedir: '/path/to/catalog1',
      json: File.read(OctocatalogDiff::Spec.fixture_path('catalogs/compilation-dir-1.json'))
    )
    @cat_compilation_dir_2 = OctocatalogDiff::Catalog.new(
      node: 'my.rspec.node',
      basedir: '/path/to/catalog2',
      json: File.read(OctocatalogDiff::Spec.fixture_path('catalogs/compilation-dir-2.json'))
    )
  end

  before(:each) do
    @logger, @logger_str = OctocatalogDiff::Spec.setup_logger
  end

  it 'should remove +/- full title changes due to compilation dirs' do
    opts = {
      ignore: [
        { type: 'Varies_Due_To_Compilation_Dir_2' },
        { type: 'Varies_Due_To_Compilation_Dir_3' },
        { type: 'Varies_Due_To_Compilation_Dir_4' }
      ]
    }
    testobj = OctocatalogDiff::Cli::Diffs.new(opts, @logger)
    result = testobj.diffs(from: @cat_compilation_dir_1, to: @cat_compilation_dir_2)
    expect(result).to eq([])
    expect(@logger_str.string).to match(%r{Varies_Due_To_Compilation_Dir_1\[/path/to/catalog2\] .*Suppressed})
    expect(@logger_str.string).to match(%r{Varies_Due_To_Compilation_Dir_1\[/path/to/catalog1\] .*Suppressed})
  end

  it 'should remove +/- partial title changes due to compilation dirs' do
    opts = { ignore:
      [
        { type: 'Varies_Due_To_Compilation_Dir_1' },
        { type: 'Varies_Due_To_Compilation_Dir_3' },
        { type: 'Varies_Due_To_Compilation_Dir_4' }
      ] }
    testobj = OctocatalogDiff::Cli::Diffs.new(opts, @logger)
    result = testobj.diffs(from: @cat_compilation_dir_1, to: @cat_compilation_dir_2)
    expect(result).to eq([])
    r1 = %r{Varies_Due_To_Compilation_Dir_2\[/aldsfjalkfjalksfd/path/to/catalog2/dflkjasfkljasdf\].*Suppressed}
    expect(@logger_str.string).to match(r1)
    r2 = %r{Varies_Due_To_Compilation_Dir_2\[/aldsfjalkfjalksfd/path/to/catalog1/dflkjasfkljasdf\].*Suppressed}
    expect(@logger_str.string).to match(r2)
  end

  it 'should remove ~ changes due to compilation dirs' do
    opts = { ignore:
      [
        { type: 'Varies_Due_To_Compilation_Dir_1' },
        { type: 'Varies_Due_To_Compilation_Dir_2' },
        { type: 'Varies_Due_To_Compilation_Dir_4' },
        { attr: "parameters\fdir_in_first_cat" },
        { attr: "parameters\fdir_in_second_cat" }
      ] }
    testobj = OctocatalogDiff::Cli::Diffs.new(opts, @logger)
    result = testobj.diffs(from: @cat_compilation_dir_1, to: @cat_compilation_dir_2)
    expect(result).to eq([])
    expect(@logger_str.string).to match(/WARN -- : Resource key.*parameters => dir .*Suppressed/)
    expect(@logger_str.string).to match(/WARN -- : Resource key.*parameters => dir_in_middle .*Suppressed/)
  end

  it 'should warn but not remove non-matching ! changes due to compilation dirs' do
    opts = { ignore:
      [
        { type: 'Varies_Due_To_Compilation_Dir_1' },
        { type: 'Varies_Due_To_Compilation_Dir_2' },
        { type: 'Varies_Due_To_Compilation_Dir_4' },
        { attr: "parameters\fdir" },
        { attr: "parameters\fdir_in_middle" }
      ] }
    testobj = OctocatalogDiff::Cli::Diffs.new(opts, @logger)
    result = testobj.diffs(from: @cat_compilation_dir_1, to: @cat_compilation_dir_2)
    expect(result.size).to eq(2)
    common_str = "Varies_Due_To_Compilation_Dir_3\fCommon Title\fparameters\f"
    expect(result[0][1]).to eq("#{common_str}dir_in_first_cat")
    expect(result[1][1]).to eq("#{common_str}dir_in_second_cat")
    expect(@logger_str.string).to match(/WARN.+Varies_Due_To_Compilation_Dir_3\[Common Title\] parameters => dir.*verify/)
  end

  it 'should warn but not remove non-matching ~ changes due to compilation dirs' do
    opts = { ignore:
      [
        { type: 'Varies_Due_To_Compilation_Dir_1' },
        { type: 'Varies_Due_To_Compilation_Dir_2' },
        { type: 'Varies_Due_To_Compilation_Dir_3' }
      ] }
    testobj = OctocatalogDiff::Cli::Diffs.new(opts, @logger)
    result = testobj.diffs(from: @cat_compilation_dir_1, to: @cat_compilation_dir_2)
    answer = [[
      '~',
      "Varies_Due_To_Compilation_Dir_4\fCommon Title\fparameters\fdir",
      '/path/to/catalog1/onetime',
      '/path/to/catalog2/twotimes',
      { 'file' => nil, 'line' => nil },
      { 'file' => nil, 'line' => nil }
    ]]
    expect(result).to eq(answer)
    expect(@logger_str.string).to match(/WARN -- : Resource key Varies_Due_To_Compilation_Dir_4.*please verify/)
  end
end
