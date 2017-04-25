# frozen_string_literal: true

require_relative 'integration_helper'
require 'json'

describe 'include-tags integration' do
  let(:default_argv) do
    [
      '--from-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/include-tags-old.json'),
      '--to-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/include-tags-new.json')
    ]
  end

  context 'with --include-tags specified' do
    let(:argv) do
      default_argv.concat ['--include-tags']
    end

    let(:result) do
      OctocatalogDiff::Integration.integration(
        argv: argv
      )
    end

    it 'should exit indicating success with differences' do
      expect(result.exitcode).to eq(2)
    end

    it 'should contain representative tag differences' do
      diffs = result.diffs
      expect(diffs.size).to eq(1)
      expect(diffs.first.change?).to eq(true)
      expect(diffs.first.structure).to eq(['tags'])
      expect(diffs.first.old_value).to eq(['tag-one', 'tag-two'])
      expect(diffs.first.new_value).to eq(['tag-one-new', 'tag-too'])
    end
  end

  context 'with --no-include-tags specified' do
  end

  context 'with --include-tags not specified' do
  end

  context 'with --ignore-tags and --include-tags specified' do
  end

  context 'with --ignore-tags and --no-include-tags specified' do
  end
end
