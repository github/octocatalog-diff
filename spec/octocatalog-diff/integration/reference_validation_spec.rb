# frozen_string_literal: true

require_relative 'integration_helper'
require 'json'

module OctocatalogDiff
  class Spec
    def self.reference_validation_catalog(role, validations)
      argv = ['--catalog-only', '-n', 'rspec-node.github.net', '--to-fact-override', "reference_validation_role=#{role}"]
      validations.each { |v| argv.concat ['--validate-references', v] }
      OctocatalogDiff::Integration.integration(
        hiera_config: 'hiera.yaml',
        spec_fact_file: 'facts.yaml',
        spec_repo: 'reference-validation',
        argv: argv
      )
    end

    def self.reference_validation_catalog_diff(catalog1, catalog2, validations)
      argv = ['-n', 'rspec-node.github.net', '--no-parallel']
      validations.each { |v| argv.concat ['--validate-references', v] }
      OctocatalogDiff::Integration.integration(
        spec_catalog_old: "reference-validation-#{catalog1}.json",
        spec_catalog_new: "reference-validation-#{catalog2}.json",
        argv: argv
      )
    end

    def self.catalog_contains_resource(result, type, title)
      catalog = OctocatalogDiff::Catalog.new(json: result.output)
      !catalog.resource(type: type, title: title).nil?
    end
  end
end

describe 'validation specifically disabled' do
  before(:all) do
    argv = ['--catalog-only', '-n', 'rspec-node.github.net', '--no-validate-references']
    @result = OctocatalogDiff::Integration.integration(
      hiera_config: 'hiera.yaml',
      spec_fact_file: 'facts.yaml',
      spec_repo: 'reference-validation',
      argv: argv
    )
  end

  it 'should return the valid catalog' do
    expect(@result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
  end
end

describe 'validation of sample catalog' do
  before(:all) do
    @result = OctocatalogDiff::Spec.reference_validation_catalog('valid', [])
  end

  it 'should return the valid catalog' do
    expect(@result.exitcode).to eq(2)
  end

  it 'should not raise any exceptions' do
    expect(@result.exception).to be_nil, OctocatalogDiff::Integration.format_exception(@result)
  end

  it 'should contain representative resources' do
    pending 'Catalog failed' unless @result.exitcode == 2
    expect(OctocatalogDiff::Spec.catalog_contains_resource(@result, 'File', '/tmp/test-main')).to eq(true)
  end
end

describe 'validation of references in computed catalog' do
  context 'with valid catalog' do
    before(:all) do
      @result = OctocatalogDiff::Spec.reference_validation_catalog('all', %w(before require subscribe notify))
    end

    it 'should succeed' do
      expect(@result.exitcode).to eq(2)
    end

    it 'should not raise any exceptions' do
      expect(@result.exception).to be_nil, OctocatalogDiff::Integration.format_exception(@result)
    end

    it 'should contain representative resources' do
      pending 'Catalog failed' unless @result.exitcode == 2
      expect(OctocatalogDiff::Spec.catalog_contains_resource(@result, 'Exec', 'subscribe caller 1')).to eq(true)
      expect(OctocatalogDiff::Spec.catalog_contains_resource(@result, 'Exec', 'subscribe target')).to eq(true)
    end
  end

  context 'with broken subscribe' do
    before(:all) do
      @result = OctocatalogDiff::Spec.reference_validation_catalog('broken-subscribe', %w(subscribe))
    end

    it 'should not succeed' do
      expect(@result.exitcode).to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
    end

    it 'should raise ReferenceValidationError' do
      expect(@result.exception).to be_a_kind_of(OctocatalogDiff::Errors::ReferenceValidationError)
    end

    it 'should have formatted error messages' do
      msg = @result.exception.message
      expect(msg).to match(/exec\[subscribe caller 1\] -> subscribe\[Exec\[subscribe target\]\]/)
      expect(msg).to match(/exec\[subscribe caller 2\] -> subscribe\[Exec\[subscribe target\]\]/)
      expect(msg).to match(/exec\[subscribe caller 2\] -> subscribe\[Exec\[subscribe target 2\]\]/)
      expect(msg).to match(/exec\[subscribe caller 3\] -> subscribe\[Exec\[subscribe target\]\]/)
      expect(msg).not_to match(/exec\[subscribe caller 3\] -> subscribe\[Exec\[subscribe caller 1\]\]/)
    end
  end

  context 'with broken before' do
    before(:all) do
      @result = OctocatalogDiff::Spec.reference_validation_catalog('broken-before', %w(before))
    end

    it 'should not succeed' do
      expect(@result.exitcode).to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
    end

    it 'should raise ReferenceValidationError' do
      expect(@result.exception).to be_a_kind_of(OctocatalogDiff::Errors::ReferenceValidationError)
    end

    it 'should have formatted error messages' do
      msg = @result.exception.message
      expect(msg).to eq('Catalog has broken reference: exec[before caller] -> before[Exec[before target]]')
    end
  end

  context 'with broken notify' do
    before(:all) do
      @result = OctocatalogDiff::Spec.reference_validation_catalog('broken-notify', %w(notify))
    end

    it 'should not succeed' do
      expect(@result.exitcode).to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
    end

    it 'should raise ReferenceValidationError' do
      expect(@result.exception).to be_a_kind_of(OctocatalogDiff::Errors::ReferenceValidationError)
    end

    it 'should have formatted error messages' do
      msg = @result.exception.message
      expect(msg).to match(/exec\[notify caller\] -> notify\[Test::Foo::Bar\[notify target\]\]/)
    end
  end

  context 'with broken require' do
    before(:all) do
      @result = OctocatalogDiff::Spec.reference_validation_catalog('broken-require', %w(require))
    end

    it 'should not succeed' do
      expect(@result.exitcode).to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
    end

    it 'should raise ReferenceValidationError' do
      expect(@result.exception).to be_a_kind_of(OctocatalogDiff::Errors::ReferenceValidationError)
    end

    it 'should have formatted error messages' do
      msg = @result.exception.message
      expect(msg).to match(/exec\[require caller\] -> require\[Exec\[require target\]\]/)
      expect(msg).to match(/exec\[require caller 3\] -> require\[Exec\[require target\]\]/)
      expect(msg).to match(/exec\[require caller 4\] -> require\[Exec\[require target\]\]/)
      expect(msg).not_to match(/exec\[require caller 2\]/)
      expect(msg).not_to match(/-> require\[Exec\[require caller\]\]/)
    end
  end

  context 'with broken subscribe but subscribe not checked' do
    before(:all) do
      @result = OctocatalogDiff::Spec.reference_validation_catalog('broken-subscribe', %w(before notify require))
    end

    it 'should succeed' do
      expect(@result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
    end

    it 'should not raise error' do
      expect(@result.exception).to be_nil
    end
  end
end

describe 'validation of alias references' do
  context 'with valid catalog' do
    before(:all) do
      @result = OctocatalogDiff::Spec.reference_validation_catalog('working-alias', %w(before require subscribe notify))
    end

    it 'should succeed' do
      expect(@result.exitcode).to eq(2)
    end

    it 'should not raise any exceptions' do
      expect(@result.exception).to be_nil, OctocatalogDiff::Integration.format_exception(@result)
    end

    it 'should contain representative resources' do
      pending 'Catalog failed' unless @result.exitcode == 2
      expect(OctocatalogDiff::Spec.catalog_contains_resource(@result, 'Exec', 'before alias caller')).to eq(true)
      expect(OctocatalogDiff::Spec.catalog_contains_resource(@result, 'Exec', 'before alias target')).to eq(true)
      expect(OctocatalogDiff::Spec.catalog_contains_resource(@result, 'Exec', 'the before alias target')).to eq(true)
    end
  end

  context 'with broken references' do
    before(:all) do
      @result = OctocatalogDiff::Spec.reference_validation_catalog('broken-alias', %w(before require subscribe notify))
    end

    it 'should not succeed' do
      expect(@result.exitcode).to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
    end

    it 'should raise ReferenceValidationError' do
      expect(@result.exception).to be_a_kind_of(OctocatalogDiff::Errors::ReferenceValidationError)
    end

    it 'should have formatted error messages' do
      msg = @result.exception.message
      expect(msg).to match(/exec\[before alias caller\] -> before\[Exec\[before alias target\]\]/)
      expect(msg).to match(/exec\[notify alias caller\] -> before\[Exec\[notify alias target\]\]/)
      expect(msg).to match(/exec\[require alias caller\] -> before\[Exec\[require alias target\]\]/)
      expect(msg).to match(/exec\[subscribe alias caller\] -> before\[Exec\[subscribe alias target\]\]/)
    end
  end
end

describe 'validation of references in catalog-diff' do
  context 'with valid catalog' do
    before(:all) do
      @result = OctocatalogDiff::Spec.reference_validation_catalog_diff(
        'ok',
        'ok-2',
        %w(before notify require subscribe)
      )
    end

    it 'should succeed' do
      expect(@result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
    end

    it 'should not raise error' do
      expect(@result.exception).to be_nil
    end

    it 'should have expected diffs' do
      diffs = @result.diffs
      expect(diffs).to be_a_kind_of(Array)
      expect(diffs.size).to eq(1)

      answer = [
        '-',
        "Exec\fbefore caller",
        {
          'type' => 'Exec',
          'title' => 'before caller',
          'tags' => ['before_callers', 'class', 'default', 'exec', 'node', 'test', 'test::before_callers'],
          'exported' => false,
          'parameters' => { 'command' => '/bin/true' }
        }
      ]
      expect(OctocatalogDiff::Spec.array_contains_partial_array?(diffs, answer)).to eq(true)
    end
  end

  context 'with broken references in to-catalog' do
    before(:all) do
      @result = OctocatalogDiff::Spec.reference_validation_catalog_diff(
        'ok',
        'broken',
        %w(before notify require subscribe)
      )
    end

    it 'should not succeed' do
      expect(@result.exitcode).to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
    end

    it 'should raise ReferenceValidationError' do
      expect(@result.exception).to be_a_kind_of(OctocatalogDiff::Errors::ReferenceValidationError)
    end

    it 'should have formatted error messages' do
      msg = @result.exception.message
      expect(msg).to match(/exec\[subscribe caller 1\] -> subscribe\[Exec\[subscribe target\]\]/)
      expect(msg).to match(/exec\[subscribe caller 2\] -> subscribe\[Exec\[subscribe target\]\]/)
      expect(msg).to match(/exec\[subscribe caller 2\] -> subscribe\[Exec\[subscribe target 2\]\]/)
      expect(msg).to match(/exec\[subscribe caller 3\] -> subscribe\[Exec\[subscribe target\]\]/)
    end
  end

  context 'with broken references in from-catalog' do
    before(:all) do
      @result = OctocatalogDiff::Spec.reference_validation_catalog_diff(
        'broken',
        'ok',
        %w(before notify require subscribe)
      )
    end

    it 'should succeed' do
      expect(@result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
    end

    it 'should not raise error' do
      expect(@result.exception).to be_nil
    end
  end

  context 'with broken references in from- and to- catalogs' do
    before(:all) do
      @result = OctocatalogDiff::Spec.reference_validation_catalog_diff(
        'broken-2',
        'broken',
        %w(before notify require subscribe)
      )
    end

    it 'should not succeed' do
      expect(@result.exitcode).to eq(-1), OctocatalogDiff::Integration.format_exception(@result)
    end

    it 'should raise ReferenceValidationError' do
      expect(@result.exception).to be_a_kind_of(OctocatalogDiff::Errors::ReferenceValidationError)
    end

    it 'should have formatted error messages from to-catalog only' do
      msg = @result.exception.message
      expect(msg).to match(/exec\[subscribe caller 1\] -> subscribe\[Exec\[subscribe target\]\]/)
      expect(msg).to match(/exec\[subscribe caller 2\] -> subscribe\[Exec\[subscribe target\]\]/)
      expect(msg).to match(/exec\[subscribe caller 2\] -> subscribe\[Exec\[subscribe target 2\]\]/)
      expect(msg).to match(/exec\[subscribe caller 3\] -> subscribe\[Exec\[subscribe target\]\]/)
      expect(msg).not_to match(/require target/)
    end
  end

  context 'with broken references, but checking not enabled' do
    before(:all) do
      @result = OctocatalogDiff::Spec.reference_validation_catalog_diff(
        'broken',
        'broken-2',
        %w()
      )
    end

    it 'should succeed' do
      expect(@result.exitcode).to eq(2), OctocatalogDiff::Integration.format_exception(@result)
    end

    it 'should not raise error' do
      expect(@result.exception).to be_nil
    end
  end
end
