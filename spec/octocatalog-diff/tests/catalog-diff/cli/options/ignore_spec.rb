# frozen_string_literal: true

require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_ignore' do
    it 'should add one additional ignore' do
      result = run_optparse(['--ignore', 'Foo[Bar]'])
      expect(result[:ignore]).to eq([{ type: 'Foo', title: 'Bar' }])
    end

    it 'should add multiple additional ignores' do
      result = run_optparse(['--ignore', 'Foo[Bar],Foo[Baz]'])
      expect(result[:ignore]).to eq([{ type: 'Foo', title: 'Bar' }, { type: 'Foo', title: 'Baz' }])
    end

    it 'should add multiple additional ignores with multiple flags' do
      result = run_optparse(['--ignore', 'Foo[Bar]', '--ignore', 'Foo[Baz]'])
      expect(result[:ignore]).to eq([{ type: 'Foo', title: 'Bar' }, { type: 'Foo', title: 'Baz' }])
    end

    it 'should handle three-way ignores with type, title, and attribute' do
      result = run_optparse(['--ignore', 'Foo[Bar]fizz::buzz'])
      expect(result[:ignore]).to eq([{ type: 'Foo', title: 'Bar', attr: "fizz\fbuzz" }])
    end

    it 'should handle three-way ignores with type, title, and attribute with form feed' do
      result = run_optparse(['--ignore', 'Foo[Bar]fizz\fbuzz'])
      expect(result[:ignore]).to eq([{ type: 'Foo', title: 'Bar', attr: "fizz\fbuzz" }])
    end

    it 'should handle three-way ignores with type, title, and attribute with leading ::' do
      result = run_optparse(['--ignore', 'Foo[Bar]::fizz::buzz'])
      expect(result[:ignore]).to eq([{ type: 'Foo', title: 'Bar', attr: "\ffizz\fbuzz" }])
    end

    it 'should handle three-way ignores with type, title, and attribute with leading form feed' do
      result = run_optparse(['--ignore', 'Foo[Bar]\ffizz\fbuzz'])
      expect(result[:ignore]).to eq([{ type: 'Foo', title: 'Bar', attr: "\ffizz\fbuzz" }])
    end

    it 'should handle three-way ignores with type, title, and attribute with wildcard title' do
      result = run_optparse(['--ignore', 'Foo[Bar*Baz]fizz\fbuzz'])
      expect(result[:ignore]).to eq([{ type: 'Foo', title: 'Bar*Baz', attr: "fizz\fbuzz" }])
    end

    it 'should set type and title to * with an attribute definition' do
      result = run_optparse(['--ignore', '*[*]::parameters::foo'])
      expect(result[:ignore]).to eq([{ type: '*', title: '*', attr: "\fparameters\ffoo" }])
    end
  end
end
