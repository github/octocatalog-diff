# frozen_string_literal: true

require_relative '../spec_helper'
require 'ostruct'
require OctocatalogDiff::Spec.require_path('/util/util')

describe OctocatalogDiff::Util::Util do
  describe '#object_is_any_of?' do
    it 'should return true when object is one of the classes' do
      object = 42
      classes = [Fixnum, Integer]
      expect(described_class.object_is_any_of?(object, classes)).to eq(true)
    end

    it 'should return false when object is not one of the classes' do
      object = :chickens
      classes = [Fixnum, Integer]
      expect(described_class.object_is_any_of?(object, classes)).to eq(false)
    end
  end
end
