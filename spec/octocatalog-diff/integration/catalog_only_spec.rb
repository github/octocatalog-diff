require_relative 'integration_helper'

describe 'a catalog-only operation' do
  before(:all) do
    @repo_dir = OctocatalogDiff::Spec.extract_fixture_repo('simple-repo')
    @result = OctocatalogDiff::Integration.integration(
      spec_fact_file: 'facts.yaml',
      output_format: :json,
      argv: [
        '--basedir', File.join(@repo_dir, 'git-repo'),
        '--hiera-config', 'config/hiera.yaml',
        '--hiera-path-strip', '/var/lib/puppet',
        '--enc', 'config/enc.sh',
        '-t', 'test-branch',
        '--catalog-only',
        '-n', 'rspec-node.github.net'
      ]
    )
  end

  after(:all) do
    FileUtils.remove_entry_secure @repo_dir if File.directory?(@repo_dir)
  end

  it 'should compile the catalog' do
    expect(@result[:exitcode]).not_to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
    expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
  end

  it 'should set the from-catalog to a no-op catalog type' do
    pending 'catalog compilation failed' unless @result[:exitcode] == 2
    from_catalog = @result[:diffs][0]
    expect(from_catalog).to be_a_kind_of(OctocatalogDiff::Catalog)
    expect(from_catalog.builder).to eq('OctocatalogDiff::Catalog::Noop')
  end

  it 'should set the to-catalog to a computed catalog type' do
    pending 'catalog compilation failed' unless @result[:exitcode] == 2
    to_catalog = @result[:diffs][1]
    expect(to_catalog).to be_a_kind_of(OctocatalogDiff::Catalog)
    expect(to_catalog.builder).to eq('OctocatalogDiff::Catalog::Computed')
  end

  it 'should have log messages indicating catalog compilations' do
    pending 'catalog compilation failed' unless @result[:exitcode] == 2
    logs = @result[:logs]
    expect(logs).to match(/Compiling catalog --catalog-only for rspec-node.github.net/)
    expect(logs).to match(/Initialized OctocatalogDiff::Catalog::Noop for from-catalog/)
    expect(logs).to match(/Initialized OctocatalogDiff::Catalog::Computed for to-catalog/)
  end

  it 'should produce a valid catalog' do
    pending 'catalog compilation failed' unless @result[:exitcode] == 2
    to_catalog = @result[:diffs][1]
    expect(to_catalog.valid?).to eq(true)
    expect(to_catalog.catalog).to be_a_kind_of(Hash)
    expect(to_catalog.catalog_json).to be_a_kind_of(String)
    expect(to_catalog.error_message).to be(nil)
  end

  it 'should produce the expected catalog' do
    pending 'catalog compilation failed' unless @result[:exitcode] == 2
    to_catalog = @result[:diffs][1]

    param1 = { 'owner' => 'root', 'group' => 'root', 'mode' => '0644', 'content' => 'Testy McTesterson' }
    expect(to_catalog.resource(type: 'File', title: '/tmp/foo')['parameters']).to eq(param1)

    param2 = { 'content' => 'Temporary file' }
    expect(to_catalog.resource(type: 'File', title: '/tmp/bar')['parameters']).to eq(param2)

    param3 = { 'content' => 'test' }
    expect(to_catalog.resource(type: 'File', title: '/tmp/baz')['parameters']).to eq(param3)
  end
end
