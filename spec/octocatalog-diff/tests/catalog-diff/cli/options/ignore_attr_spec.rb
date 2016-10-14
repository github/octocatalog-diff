require_relative '../options_helper'

describe OctocatalogDiff::CatalogDiff::Cli::Options do
  describe '#opt_ignore_attr' do
    it 'should add one additional ignore' do
      result = run_optparse(['--ignore-attr', 'attr1'])
      expect(result[:ignore]).to eq([{ attr: 'attr1' }])
    end

    it 'should add multiple additional ignores' do
      result = run_optparse(['--ignore-attr', 'attr1,attr2'])
      expect(result[:ignore]).to eq([{ attr: 'attr1' }, { attr: 'attr2' }])
    end

    it 'should add multiple additional ignores with multiple flags' do
      result = run_optparse(['--ignore-attr', 'attr1', '--ignore-attr', 'attr2'])
      expect(result[:ignore]).to eq([{ attr: 'attr1' }, { attr: 'attr2' }])
    end

    it 'should convert literal backslash-f into form feed for separator' do
      result = run_optparse(['--ignore-attr', 'foo\fbar\fbaz'])
      expect(result[:ignore]).to eq([{ attr: "foo\fbar\fbaz" }])
    end

    it 'should convert :: into form feed for separator' do
      result = run_optparse(['--ignore-attr', 'foo::bar::baz'])
      expect(result[:ignore]).to eq([{ attr: "foo\fbar\fbaz" }])
    end
  end
end
