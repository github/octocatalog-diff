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

    def self.catalog_contains_resource(result, type, title)
      catalog = OctocatalogDiff::Catalog.new(json: result.output)
      !catalog.resource(type: type, title: title).nil?
    end
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
      expect(@result.exception).to be_a_kind_of(OctocatalogDiff::Catalog::ReferenceValidationError)
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
      expect(@result.exception).to be_a_kind_of(OctocatalogDiff::Catalog::ReferenceValidationError)
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
      expect(@result.exception).to be_a_kind_of(OctocatalogDiff::Catalog::ReferenceValidationError)
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
      expect(@result.exception).to be_a_kind_of(OctocatalogDiff::Catalog::ReferenceValidationError)
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

describe 'validation of references in provided catalog' do
  context 'with valid catalog' do
    it 'should succeed' do
    end
  end

  context 'with broken references' do
    it 'should not succeed' do
    end

    it 'should raise error' do
    end
  end
end

describe 'validation of references in catalog-diff' do
  context 'with broken references in from-catalog' do
    it 'should succeed' do
    end
  end

  context 'with broken references in to-catalog' do
    it 'should not succeed' do
    end

    it 'should raise error' do
    end
  end

  context 'with broken references in both from- and to- catalogs' do
    it 'should not succeed' do
    end

    it 'should raise error' do
    end
  end
end
