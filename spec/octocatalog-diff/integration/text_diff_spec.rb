# frozen_string_literal: true

require_relative '../tests/spec_helper'

require OctocatalogDiff::Spec.require_path('catalog')
require OctocatalogDiff::Spec.require_path('catalog-diff/differ')
require OctocatalogDiff::Spec.require_path('catalog-diff/display')

require 'json'

describe 'text diff display for whitespace' do
  let(:base_catalog) do
    {
      'resources' => [
        {
          'type'       => 'File',
          'title'      => '/tmp/foo',
          'parameters' => { 'content' => 'THIS SHOULD BE OVERRIDDEN' }
        }
      ]
    }
  end

  let(:display_opts) { { format: :text } }
  let(:logger) { OctocatalogDiff::Spec.setup_logger.first }
  let(:diff_opts) { { logger: logger } }

  def build_catalog(hash_in, string_in)
    hash_in['resources'].first['parameters']['content'] = string_in
    OctocatalogDiff::Catalog.new(json: JSON.generate(hash_in))
  end

  context 'single line identical' do
    it 'should display no diffs at all' do
      catalog1 = build_catalog(base_catalog, 'file line')
      catalog2 = build_catalog(base_catalog, 'file line')
      diff = OctocatalogDiff::CatalogDiff::Differ.new(diff_opts, catalog1, catalog2)
      result = OctocatalogDiff::CatalogDiff::Display.output(diff, display_opts, logger)
      answer = []
      expect(result).to eq(answer)
    end
  end

  context 'single lines with different newlines' do
    it 'should display newline message when newline exists in old' do
      catalog1 = build_catalog(base_catalog, "file line\n")
      catalog2 = build_catalog(base_catalog, 'file line')
      diff = OctocatalogDiff::CatalogDiff::Differ.new(diff_opts, catalog1, catalog2)
      result = OctocatalogDiff::CatalogDiff::Display.output(diff, display_opts, logger)
      answer = [
        '  File[/tmp/foo] =>',
        '   parameters =>',
        '     content =>',
        '      - file line',
        '      + file line',
        '      \\ No newline at end of file',
        '*******************************************'
      ]
      expect(result).to eq(answer)
    end

    it 'should display newline message when newline exists in new' do
      catalog1 = build_catalog(base_catalog, 'file line')
      catalog2 = build_catalog(base_catalog, "file line\n")
      diff = OctocatalogDiff::CatalogDiff::Differ.new(diff_opts, catalog1, catalog2)
      result = OctocatalogDiff::CatalogDiff::Display.output(diff, display_opts, logger)
      answer = [
        '  File[/tmp/foo] =>',
        '   parameters =>',
        '     content =>',
        '      - file line',
        '      \\ No newline at end of file',
        '      + file line',
        '*******************************************'
      ]
      expect(result).to eq(answer)
    end
  end

  context 'single line vs. multiple line' do
    it 'should display newline message for old' do
      catalog1 = build_catalog(base_catalog, 'file line')
      catalog2 = build_catalog(base_catalog, "file line\nfile line\n")
      diff = OctocatalogDiff::CatalogDiff::Differ.new(diff_opts, catalog1, catalog2)
      result = OctocatalogDiff::CatalogDiff::Display.output(diff, display_opts, logger)
      answer = [
        '  File[/tmp/foo] =>',
        '   parameters =>',
        '     content =>',
        '      @@ -1 +1,2 @@',
        '      -file line',
        '      \\ No newline at end of file',
        '      +file line',
        '      +file line',
        '*******************************************'
      ]
      expect(result).to eq(answer)
    end
  end

  context 'multiple lines with different newlines' do
    it 'should display newline message when newline exists in old' do
      catalog1 = build_catalog(base_catalog, "file line\nfile line\n")
      catalog2 = build_catalog(base_catalog, "file line\nfile line")
      diff = OctocatalogDiff::CatalogDiff::Differ.new(diff_opts, catalog1, catalog2)
      result = OctocatalogDiff::CatalogDiff::Display.output(diff, display_opts, logger)
      answer = [
        '  File[/tmp/foo] =>',
        '   parameters =>',
        '     content =>',
        '      @@ -1,2 +1,2 @@',
        '       file line',
        '      -file line',
        '      +file line',
        '      \\ No newline at end of file',
        '*******************************************'
      ]
      expect(result).to eq(answer)
    end

    it 'should display newline message when newline exists in new' do
      catalog1 = build_catalog(base_catalog, "file line\nfile line")
      catalog2 = build_catalog(base_catalog, "file line\nfile line\n")
      diff = OctocatalogDiff::CatalogDiff::Differ.new(diff_opts, catalog1, catalog2)
      result = OctocatalogDiff::CatalogDiff::Display.output(diff, display_opts, logger)
      answer = [
        '  File[/tmp/foo] =>',
        '   parameters =>',
        '     content =>',
        '      @@ -1,2 +1,2 @@',
        '       file line',
        '      -file line',
        '      \\ No newline at end of file',
        '      +file line',
        '*******************************************'
      ]
      expect(result).to eq(answer)
    end
  end

  context 'both multi-line strings do not end in newline' do
    it 'should display differences but no newline alert' do
      catalog1 = build_catalog(base_catalog, "file line\nold line\nlast line")
      catalog2 = build_catalog(base_catalog, "file line\nnew line\nlast line")
      diff = OctocatalogDiff::CatalogDiff::Differ.new(diff_opts, catalog1, catalog2)
      result = OctocatalogDiff::CatalogDiff::Display.output(diff, display_opts, logger)
      answer = [
        '  File[/tmp/foo] =>',
        '   parameters =>',
        '     content =>',
        '      @@ -1,3 +1,3 @@',
        '       file line',
        '      -old line',
        '      +new line',
        '       last line',
        '*******************************************'
      ]
      expect(result).to eq(answer)
    end
  end

  context 'different line endings' do
    it 'should handle windows vs. unix' do
      catalog1 = build_catalog(base_catalog, "file line\r\nline two\r\nline three\r\n")
      catalog2 = build_catalog(base_catalog, "file line\nline two\nline three\n")
      diff = OctocatalogDiff::CatalogDiff::Differ.new(diff_opts, catalog1, catalog2)
      result = OctocatalogDiff::CatalogDiff::Display.output(diff, display_opts, logger)
      answer = [
        '  File[/tmp/foo] =>',
        '   parameters =>',
        '     content =>',
        '      @@ -1,3 +1,3 @@',
        '      -file line\\r',
        '      -line two\\r',
        '      -line three\\r',
        '      +file line',
        '      +line two',
        '      +line three',
        '*******************************************'
      ]
      expect(result).to eq(answer)
    end
  end

  context 'whitespace on single line' do
    it 'should display proper diffs for leading whitespace difference' do
      catalog1 = build_catalog(base_catalog, '    file line')
      catalog2 = build_catalog(base_catalog, 'file line')
      diff = OctocatalogDiff::CatalogDiff::Differ.new(diff_opts, catalog1, catalog2)
      result = OctocatalogDiff::CatalogDiff::Display.output(diff, display_opts, logger)
      answer = [
        '  File[/tmp/foo] =>',
        '   parameters =>',
        '     content =>',
        '      -     file line',
        '      + file line',
        '*******************************************'
      ]
      expect(result).to eq(answer)
    end

    it 'should display proper diffs for trailing whitespace difference' do
      catalog1 = build_catalog(base_catalog, 'file line    ')
      catalog2 = build_catalog(base_catalog, 'file line')
      diff = OctocatalogDiff::CatalogDiff::Differ.new(diff_opts, catalog1, catalog2)
      result = OctocatalogDiff::CatalogDiff::Display.output(diff, display_opts, logger)
      answer = [
        '  File[/tmp/foo] =>',
        '   parameters =>',
        '     content =>',
        '      - file line____',
        '      + file line',
        '*******************************************'
      ]
      expect(result).to eq(answer)
    end

    it 'should display proper diffs for trailing whitespace size difference' do
      catalog1 = build_catalog(base_catalog, 'file line    ')
      catalog2 = build_catalog(base_catalog, 'file line   ')
      diff = OctocatalogDiff::CatalogDiff::Differ.new(diff_opts, catalog1, catalog2)
      result = OctocatalogDiff::CatalogDiff::Display.output(diff, display_opts, logger)
      answer = [
        '  File[/tmp/foo] =>',
        '   parameters =>',
        '     content =>',
        '      - file line____',
        '      + file line___',
        '*******************************************'
      ]
      expect(result).to eq(answer)
    end
  end

  context 'whitespace manipulation with colors enabled' do
    let(:display_opts) { { format: :color_text } }

    it 'should properly add space between +/- and single string diff' do
      catalog1 = build_catalog(base_catalog, 'old value')
      catalog2 = build_catalog(base_catalog, 'new value')
      diff = OctocatalogDiff::CatalogDiff::Differ.new(diff_opts, catalog1, catalog2)
      result = OctocatalogDiff::CatalogDiff::Display.output(diff, display_opts, logger)
      answer = [
        '  File[/tmp/foo] =>',
        '   parameters =>',
        '     content =>',
        "      \e[31m- old value\e[0m",
        "      \e[32m+ new value\e[0m",
        '*******************************************'
      ]
      expect(result).to eq(answer)
    end

    it 'should properly colorize newline warning in old diff' do
      catalog1 = build_catalog(base_catalog, 'file line')
      catalog2 = build_catalog(base_catalog, "file line\n")
      diff = OctocatalogDiff::CatalogDiff::Differ.new(diff_opts, catalog1, catalog2)
      result = OctocatalogDiff::CatalogDiff::Display.output(diff, display_opts, logger)
      answer = [
        '  File[/tmp/foo] =>',
        '   parameters =>',
        '     content =>',
        "      \e[31m- file line\e[0m",
        '      \\ No newline at end of file',
        "      \e[32m+ file line\e[0m",
        '*******************************************'
      ]
      expect(result).to eq(answer)
    end

    it 'should properly colorize newline warning in new diff' do
      catalog1 = build_catalog(base_catalog, "file line\n")
      catalog2 = build_catalog(base_catalog, 'file line')
      diff = OctocatalogDiff::CatalogDiff::Differ.new(diff_opts, catalog1, catalog2)
      result = OctocatalogDiff::CatalogDiff::Display.output(diff, display_opts, logger)
      answer = [
        '  File[/tmp/foo] =>',
        '   parameters =>',
        '     content =>',
        "      \e[31m- file line\e[0m",
        "      \e[32m+ file line\e[0m",
        '      \\ No newline at end of file',
        '*******************************************'
      ]
      expect(result).to eq(answer)
    end
  end
end
