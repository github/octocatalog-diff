# frozen_string_literal: true

require_relative 'integration_helper'
require 'json'

describe 'YAML file suppression for identical diffs' do
  context 'with YAML diff suppression disabled' do
    before(:all) do
      argv = ['-n', 'rspec-node.github.net', '--to-fact-override', 'role=bar']
      hash = { hiera_config: 'hiera.yaml', spec_fact_file: 'facts.yaml', spec_repo: 'yaml-diff' }
      @result = OctocatalogDiff::Integration.integration(hash.merge(argv: argv))
    end

    it 'should compile without error' do
      expect(@result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
      expect(@result.exception).to be_nil
    end

    it 'should contain the correct number of diffs' do
      expect(@result.diffs.size).to eq(22)
    end

    it 'should contain the "similar JSON" static file as a diff' do
      arr = @result.diffs
      answer = ['~', "File\f/tmp/static/similar-yaml.json\fparameters\fcontent"]
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(arr, answer)).to eq(true)
    end

    it 'should contain the "similar YAML" static file as a diff' do
      arr = @result.diffs
      answer = ['~', "File\f/tmp/static/similar-yaml.yaml\fparameters\fcontent"]
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(arr, answer)).to eq(true)
    end

    it 'should contain the "similar JSON" template file as a diff' do
      arr = @result.diffs
      answer = ['~', "File\f/tmp/template/similar-yaml.json\fparameters\fcontent"]
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(arr, answer)).to eq(true)
    end

    it 'should contain the "similar YAML" template file as a diff' do
      arr = @result.diffs
      answer = ['~', "File\f/tmp/template/similar-yaml.yaml\fparameters\fcontent"]
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(arr, answer)).to eq(true)
    end
  end

  context 'with YAML diff suppression enabled' do
    before(:all) do
      argv = ['-n', 'rspec-node.github.net', '--to-fact-override', 'role=bar', '--filters', 'YAML']
      hash = { hiera_config: 'hiera.yaml', spec_fact_file: 'facts.yaml', spec_repo: 'yaml-diff' }
      @result = OctocatalogDiff::Integration.integration(hash.merge(argv: argv))
    end

    it 'should compile without error' do
      expect(@result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
      expect(@result.exception).to be_nil
    end

    it 'should contain the correct number of diffs' do
      expect(@result.diffs.size).to eq(20)
    end

    it 'should contain the "similar JSON" static file as a diff' do
      arr = @result.diffs
      answer = ['~', "File\f/tmp/static/similar-yaml.json\fparameters\fcontent"]
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(arr, answer)).to eq(true)
    end

    it 'should not contain the "similar YAML" static file as a diff' do
      arr = @result.diffs
      answer = ['~', "File\f/tmp/static/similar-yaml.yaml\fparameters\fcontent"]
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(arr, answer)).to eq(false)
    end

    it 'should contain the "similar JSON" template file as a diff' do
      arr = @result.diffs
      answer = ['~', "File\f/tmp/template/similar-yaml.json\fparameters\fcontent"]
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(arr, answer)).to eq(true)
    end

    it 'should not contain the "similar YAML" template file as a diff' do
      arr = @result.diffs
      answer = ['~', "File\f/tmp/template/similar-yaml.yaml\fparameters\fcontent"]
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(arr, answer)).to eq(false)
    end
  end
end
