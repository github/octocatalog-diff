# frozen_string_literal: true

require_relative 'integration_helper'

describe 'script path override' do
  context 'without any scripts' do
    it 'should fail' do
      result = OctocatalogDiff::Integration.integration(
        spec_fact_file: 'facts.yaml',
        argv: [
          '-n', 'rspec-node.github.net', '--no-parallel',
          '-t', 'ignore-tags-new', '-f', 'ignore-tags-old',
          '--basedir', OctocatalogDiff::Spec.fixture_path('repos/default'),
          '--override-script-path', OctocatalogDiff::Spec.fixture_path('scripts')
        ]
      )
      expect(result.exitcode).to eq(-1)
      expect(result.logs).to match(/Git checkout error: Git archive ignore-tags-old->/)
    end
  end

  context 'with an overridden git-extract.sh script' do
    before(:each) do
      ENV['FIXTURE_DIR'] = OctocatalogDiff::Spec.fixture_path('repos')
    end

    after(:each) do
      ENV.delete('FIXTURE_DIR')
    end

    it 'should return expected diff' do
      result = OctocatalogDiff::Integration.integration(
        spec_fact_file: 'facts.yaml',
        argv: [
          '-n', 'rspec-node.github.net', '--no-parallel',
          '-t', 'ignore-tags-new', '-f', 'ignore-tags-old',
          '--basedir', OctocatalogDiff::Spec.fixture_path('repos/default'),
          '--pass-env-vars', 'FIXTURE_DIR',
          '--override-script-path', OctocatalogDiff::Spec.fixture_path('override-scripts')
        ]
      )
      expect(result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(result)
      expect(result.logs).to match(/Selecting.+git-extract.sh from override script path/)
      expect(result.diffs.size).to eq(30) # See ignore_tags_spec.rb
    end
  end
end
