# frozen_string_literal: true

require_relative '../../spec_helper'
require OctocatalogDiff::Spec.require_path('/catalog-diff/filter/compilation_dir')

describe OctocatalogDiff::CatalogDiff::Filter::CompilationDir do
  let(:opts) { { from_compilation_dir: '/path/to/catalog1', to_compilation_dir: '/path/to/catalog2' } }

  before(:each) do
    @logger, @logger_str = OctocatalogDiff::Spec.setup_logger
  end

  subject { described_class.new([], @logger) }

  context '+/- full title change' do
    it 'should remove due to compilation dirs in to-catalog' do
      diff = [
        '+',
        "Varies_Due_To_Compilation_Dir_1\f/path/to/catalog2",
        {
          'type' => 'Varies_Due_To_Compilation_Dir_1',
          'title' => '/path/to/catalog2',
          'tags' => ['ignoreme'],
          'exported' => false
        },
        { 'file' => nil, 'line' => nil }
      ]
      expect(subject.filtered?(diff, opts)).to eq(true)
    end

    it 'should remove due to compilation dirs in from-catalog' do
      diff = [
        '-',
        "Varies_Due_To_Compilation_Dir_1\f/path/to/catalog1",
        {
          'type' => 'Varies_Due_To_Compilation_Dir_1',
          'title' => '/path/to/catalog1',
          'tags' => ['ignoreme'],
          'exported' => false
        },
        { 'file' => nil, 'line' => nil }
      ]
      expect(subject.filtered?(diff, opts)).to eq(true)
    end

    it 'should not remove a non-matching directory' do
      diff = [
        '-',
        "Varies_Due_To_Compilation_Dir_1\f/path/to/catalog3",
        {
          'type' => 'Varies_Due_To_Compilation_Dir_1',
          'title' => '/path/to/catalog3',
          'tags' => ['ignoreme'],
          'exported' => false
        },
        { 'file' => nil, 'line' => nil }
      ]
      expect(subject.filtered?(diff, opts)).to eq(false)
    end
  end

  context '+/- partial title change' do
    it 'should remove due to compilation dirs in to-catalog' do
      diff = [
        '+',
        "Varies_Due_To_Compilation_Dir_1\f/aldsfjalkfjalksfd/path/to/catalog2/aldsfjalkfjalksfd",
        {
          'type' => 'Varies_Due_To_Compilation_Dir_1',
          'title' => '/aldsfjalkfjalksfd/path/to/catalog2/aldsfjalkfjalksfd',
          'tags' => ['ignoreme'],
          'exported' => false
        },
        { 'file' => nil, 'line' => nil }
      ]
      expect(subject.filtered?(diff, opts)).to eq(true)
    end

    it 'should remove due to compilation dirs in from-catalog' do
      diff = [
        '-',
        "Varies_Due_To_Compilation_Dir_1\f/aldsfjalkfjalksfd/path/to/catalog1/aldsfjalkfjalksfd",
        {
          'type' => 'Varies_Due_To_Compilation_Dir_1',
          'title' => '/aldsfjalkfjalksfd/path/to/catalog1/aldsfjalkfjalksfd',
          'tags' => ['ignoreme'],
          'exported' => false
        },
        { 'file' => nil, 'line' => nil }
      ]
      expect(subject.filtered?(diff, opts)).to eq(true)
    end

    it 'should not remove a non-matching directory' do
      diff = [
        '-',
        "Varies_Due_To_Compilation_Dir_1\f/aldsfjalkfjalksfd/path/to/catalog3/aldsfjalkfjalksfd",
        {
          'type' => 'Varies_Due_To_Compilation_Dir_1',
          'title' => '/aldsfjalkfjalksfd/path/to/catalog3/aldsfjalkfjalksfd',
          'tags' => ['ignoreme'],
          'exported' => false
        },
        { 'file' => nil, 'line' => nil }
      ]
      expect(subject.filtered?(diff, opts)).to eq(false)
    end
  end

  context '~ value changes' do
    it 'should remove a change where directories are a partial match' do
      diff = [
        '~',
        "Varies_Due_To_Compilation_Dir_3\fCommon Title\fparameters\fdir_in_middle",
        '/asdfjkafds/path/to/catalog1/slkdfjasflkd',
        '/asdfjkafds/path/to/catalog2/slkdfjasflkd',
        { 'file' => nil, 'line' => nil },
        { 'file' => nil, 'line' => nil }
      ]
      expect(subject.filtered?(diff, opts)).to eq(true)
    end

    it 'should remove a change where directories are a full match' do
      diff = [
        '~',
        "Varies_Due_To_Compilation_Dir_3\fCommon Title\fparameters\fdir",
        '/path/to/catalog1',
        '/path/to/catalog2',
        { 'file' => nil, 'line' => nil },
        { 'file' => nil, 'line' => nil }
      ]
      expect(subject.filtered?(diff, opts)).to eq(true)
    end

    it 'should not remove a change where directories are inverted' do
      diff = [
        '~',
        "Varies_Due_To_Compilation_Dir_3\fCommon Title\fparameters\fdir",
        '/path/to/catalog2',
        '/path/to/catalog1',
        { 'file' => nil, 'line' => nil },
        { 'file' => nil, 'line' => nil }
      ]
      expect(subject.filtered?(diff, opts)).to eq(false)
    end

    it 'should not remove a change where directories do not match' do
      diff = [
        '~',
        "Varies_Due_To_Compilation_Dir_3\fCommon Title\fparameters\fdir",
        '/var/tmp/alsdfksfmd',
        '/var/tmp/adfklweoif',
        { 'file' => nil, 'line' => nil },
        { 'file' => nil, 'line' => nil }
      ]
      expect(subject.filtered?(diff, opts)).to eq(false)
    end
  end

  context '~ partial indeterminate matches' do
    let(:diff) do
      [
        '~',
        "Varies_Due_To_Compilation_Dir_3\fCommon Title\fparameters\fdir",
        '/var/tmp/alsdfksfmd',
        '/path/to/catalog2',
        { 'file' => nil, 'line' => nil },
        { 'file' => nil, 'line' => nil }
      ]
    end

    it 'should not remove changes that do not match fully' do
      expect(subject.filtered?(diff, opts)).to eq(false)
    end

    it 'should log warning message' do
      subject.filtered?(diff, opts)
      expect(@logger_str.string).to match(/WARN.*Varies_Due_To_Compilation_Dir_3\[Common Title\] parameters => dir.+differences/)
    end
  end
end
