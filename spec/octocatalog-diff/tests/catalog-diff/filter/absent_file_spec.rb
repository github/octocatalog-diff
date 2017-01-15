# frozen_string_literal: true

require_relative '../../spec_helper'
require OctocatalogDiff::Spec.require_path('/api/v1/diff')
require OctocatalogDiff::Spec.require_path('/catalog')
require OctocatalogDiff::Spec.require_path('/catalog-diff/filter/absent_file')

describe OctocatalogDiff::CatalogDiff::Filter::AbsentFile do
  it 'should filter out some attributes for ensure=>absent file' do
    orig = [
      ['~', "File\f/tmp/foo\fparameters\fensure", 'file', 'absent'],
      ['~', "File\f/tmp/foo\fparameters\fowner", 'root', 'nobody'],
      ['~', "File\f/tmp/foo\fparameters\fbackup", true, nil],
      ['~', "File\f/tmp/foo\fparameters\fforce", false, nil],
      ['~', "File\f/tmp/foo\fparameters\fprovider", 'root', nil],
      ['~', "File\f/tmp/bar\fparameters\fensure", 'file', 'link'],
      ['~', "File\f/tmp/bar\fparameters\ftarget", nil, '/tmp/foo'],
      ['~', "Exec\f/tmp/bar\fparameters\fcommand", nil, '/tmp/foo']
    ]
    obj = orig.map { |x| OctocatalogDiff::API::V1::Diff.construct(x) }
    testobj = described_class.new(obj)
    result = obj.reject { |x| testobj.filtered?(x) }
    expect(result).to eq(obj.values_at(0, 2, 3, 4, 5, 6, 7))
  end
end
