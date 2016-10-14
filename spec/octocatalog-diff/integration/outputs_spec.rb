require_relative 'integration_helper'

require 'json'

describe 'output formats integration' do
  # This set of tests always uses the same set of arguments, except for the
  # output style and method.
  let(:default_argv) do
    [
      '--from-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/catalog-1.json'),
      '--to-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/catalog-2.json')
    ]
  end

  before(:each) do
    @tmpdir = Dir.mktmpdir
  end

  after(:each) do
    OctocatalogDiff::Spec.clean_up_tmpdir(@tmpdir)
  end

  it 'should write human readable output to a specified file' do
    output_file = File.join(@tmpdir, 'octo-output.txt')
    argv = default_argv.concat ['-o', output_file]
    result = OctocatalogDiff::Integration.integration(argv: argv)
    expect(result[:exitcode]).to eq(2), OctocatalogDiff::Integration.format_exception(result)
    expect(result[:logs]).to match(/Wrote diff to #{Regexp.escape(output_file)}/)
    expect(File.file?(output_file)).to eq(true)
    content = File.read(output_file)
    expect(content.split(/\n/).first).to match(%r{File\[/etc/puppet/puppet.conf\]})
  end

  it 'should write human readable output to the screen' do
    result = OctocatalogDiff::Integration.integration(argv: default_argv)
    expect(result[:exitcode]).to eq(2), OctocatalogDiff::Integration.format_exception(result)
    expect(result[:logs]).to match(/Generating colored text output/)
    pattern = Regexp.new(Regexp.escape("\e[0;31;49m      - [\"FOO\", \"BAR\", \"BAZ\"]\e[0m"))
    expect(result[:output]).to match(pattern)
  end

  it 'should write human readable output to the screen with no color' do
    result = OctocatalogDiff::Integration.integration(argv: default_argv.concat(['--no-color']))
    expect(result[:exitcode]).to eq(2), OctocatalogDiff::Integration.format_exception(result)
    expect(result[:logs]).to match(/Generating non-colored text output/)
    pattern = Regexp.new(Regexp.escape("\e[0;31;49m      - [\"FOO\", \"BAR\", \"BAZ\"]\e[0m"))
    expect(result[:output]).not_to match(pattern)
    pattern = Regexp.new(Regexp.escape('      - ["FOO", "BAR", "BAZ"]'))
    expect(result[:output]).to match(pattern)
  end

  it 'should write JSON output to a specified file' do
    output_file = File.join(@tmpdir, 'octo-output.json')
    argv = default_argv.concat ['-o', output_file, '--output-format', 'json']
    result = OctocatalogDiff::Integration.integration(argv: argv)
    expect(result[:exitcode]).to eq(2), OctocatalogDiff::Integration.format_exception(result)
    expect(result[:logs]).to match(/Wrote diff to #{Regexp.escape(output_file)}/)
    expect(File.file?(output_file)).to eq(true)
    content = File.read(output_file)
    data = JSON.parse(content)
    expect(data).to be_a_kind_of(Hash)
    expect(data['header']).to eq(nil)
    expect(data['diff']).to be_a_kind_of(Array)
  end

  it 'should write JSON output to the screen' do
    argv = default_argv.concat ['--output-format', 'json']
    result = OctocatalogDiff::Integration.integration(argv: argv)
    expect(result[:exitcode]).to eq(2), OctocatalogDiff::Integration.format_exception(result)
    expect(result[:logs]).to match(/Generating JSON output/)
    data = JSON.parse(result[:output])
    expect(data).to be_a_kind_of(Hash)
    expect(data['header']).to eq(nil)
    expect(data['diff']).to be_a_kind_of(Array)
  end

  it 'should include a custom header in JSON output' do
    argv = default_argv.concat ['--output-format', 'json', '--header', 'chicken']
    result = OctocatalogDiff::Integration.integration(argv: argv)
    expect(result[:exitcode]).to eq(2), OctocatalogDiff::Integration.format_exception(result)
    expect(result[:logs]).to match(/Generating JSON output/)
    data = JSON.parse(result[:output])
    expect(data).to be_a_kind_of(Hash)
    expect(data['header']).to eq('chicken')
    expect(data['diff']).to be_a_kind_of(Array)
  end

  it 'should include a custom header in human readable output' do
    output_file = File.join(@tmpdir, 'octo-output.txt')
    argv = default_argv.concat ['-o', output_file, '--header', 'chicken']
    result = OctocatalogDiff::Integration.integration(argv: argv)
    expect(result[:exitcode]).to eq(2), OctocatalogDiff::Integration.format_exception(result)
    expect(result[:logs]).to match(/Wrote diff to #{Regexp.escape(output_file)}/)
    expect(File.file?(output_file)).to eq(true)
    content = File.read(output_file)
    expect(content.split(/\n/).first).to match(/^chicken$/)
  end

  it 'should not display detail of added items' do
    argv = [
      '--from-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/catalog-empty.json'),
      '--to-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/catalog-2.json'),
      '--no-color'
    ]
    result = OctocatalogDiff::Integration.integration(argv: argv)
    expect(result[:exitcode]).to eq(2), OctocatalogDiff::Integration.format_exception(result)
    expect(result[:output]).to match(/\+ Package\[ruby1.8-dev\]/)
    expect(result[:output]).not_to match(/"new-parameter": "new value"/)
  end

  it 'should display detail of added items' do
    argv = [
      '--from-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/catalog-empty.json'),
      '--to-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/catalog-2.json'),
      '--display-detail-add', '--no-color'
    ]
    result = OctocatalogDiff::Integration.integration(argv: argv)
    expect(result[:exitcode]).to eq(2), OctocatalogDiff::Integration.format_exception(result)
    expect(result[:output]).to match(/\+ Package\[ruby1.8-dev\] =>/)
    expect(result[:output]).to match(/"new-parameter": "new value"/)
  end

  it 'should not display file source and line' do
    argv = [
      '--from-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/catalog-empty.json'),
      '--to-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/catalog-2.json'),
      '--no-color'
    ]
    result = OctocatalogDiff::Integration.integration(argv: argv)
    expect(result[:exitcode]).to eq(2), OctocatalogDiff::Integration.format_exception(result)
    expect(result[:output]).not_to match(%r{/environments/production/modules/openssl/manifests/package.pp:16})
    expect(result[:output]).to match(/\+ Apt::Pin\[openssl\]/)
  end

  it 'should display file source and line' do
    argv = [
      '--from-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/catalog-empty.json'),
      '--to-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/catalog-2.json'),
      '--display-source', '--no-color'
    ]
    result = OctocatalogDiff::Integration.integration(argv: argv)
    expect(result[:exitcode]).to eq(2), OctocatalogDiff::Integration.format_exception(result)
    expect(result[:output]).to match(%r{/environments/production/modules/openssl/manifests/package.pp:16})
    expect(result[:output]).to match(/\+ Apt::Pin\[openssl\]/)
  end
end
