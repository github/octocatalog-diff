require_relative '../../spec_helper'
require OctocatalogDiff::Spec.require_path('/catalog-util/enc/noop')

describe OctocatalogDiff::CatalogUtil::ENC::Noop do
  describe '#content' do
    it 'should return expected value from noop backend' do
      testobj = OctocatalogDiff::CatalogUtil::ENC::Noop.new(foo: 'bar')
      expect(testobj.content).to eq('')
    end
  end

  describe '#error_message' do
    it 'should return expected value from noop backend' do
      testobj = OctocatalogDiff::CatalogUtil::ENC::Noop.new(foo: 'bar')
      expect(testobj.error_message).to eq(nil)
    end
  end
end
