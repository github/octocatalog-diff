require_relative 'integration_helper'

describe 'ignore wildcards integration' do
  before(:all) do
    args = [
      '--ignore', 'ssh_authorized_key[root@*]',
      '--to-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/default-catalog-changed.json'),
      '--hiera-config', 'environments/production/config/hiera.yaml',
      '--hiera-path-strip', '/var/lib/puppet'
    ]
    @result = OctocatalogDiff::Integration.integration(
      spec_repo_old: 'default',
      spec_fact_file: 'valid-facts.yaml',
      argv: args
    )
    @exception_message = OctocatalogDiff::Integration.format_exception(@result)
  end

  it 'should succeed' do
    expect(@result[:exitcode]).not_to eq(-1), @exception_message
    expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
    expect(@result[:diffs]).to be_a_kind_of(Array)
  end

  it 'should have the correct catalog-diff result size' do
    pending 'catalog-diff failed' unless @result[:exitcode] == 2
    expect(@result[:diffs].size).to eq(6), @result[:diffs].map(&:inspect).join("\n")
  end

  it 'should not contain the ignored item' do
    pending 'catalog-diff failed' unless @result[:exitcode] == 2
    title = "Ssh_authorized_key\froot@6def27049c06f48eea8b8f37329f40799d07dc84"
    should_be_ignored = @result[:diffs].select { |x| x[1] == title }
    expect(should_be_ignored.size).to eq(0), should_be_ignored.inspect
  end
end
