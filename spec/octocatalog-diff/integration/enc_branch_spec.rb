# frozen_string_literal: true

require_relative 'integration_helper'

require 'fileutils'
require 'json'
require 'yaml'

describe 'with different ENCs per catalog' do
  before(:all) do
    @result = OctocatalogDiff::Integration.integration(
      spec_repo: 'enc-diff',
      spec_fact_file: 'facts.yaml',
      argv: [
        '--from-enc', OctocatalogDiff::Spec.fixture_path('repos/enc-diff/config/enc-1.sh'),
        '--to-enc', OctocatalogDiff::Spec.fixture_path('repos/enc-diff/config/enc-2.sh')
      ]
    )
  end

  it 'should run without an error' do
    expect(@result[:exitcode]).not_to eq(-1), "Internal error: #{OctocatalogDiff::Integration.format_exception(@result)}"
    expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
    expect(@result[:diffs].size).to eq(2), @result[:diffs].map(&:inspect).join("\n")
  end

  it 'should have /tmp/bar influenced by ENC' do
    pending 'catalog-diff failed' unless @result[:exitcode] == 2
    obj = @result[:diffs].select { |x| x[1] == "File\f/tmp/bar\fparameters\fensure" }
    expect(obj.size).to eq(1)
    expect(obj[0][2]).to eq('absent')
    expect(obj[0][3]).to eq(nil)

    obj2 = @result[:diffs].select { |x| x[1] == "File\f/tmp/bar\fparameters\fcontent" }
    expect(obj2.size).to eq(1)
    expect(obj2[0][2]).to eq(nil)
    expect(obj2[0][3]).to eq('foo')
  end
end
