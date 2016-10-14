require_relative '../spec_helper'
require 'fileutils'
require OctocatalogDiff::Spec.require_path('/catalog-util/command')

describe OctocatalogDiff::CatalogUtil::Command do
  describe '#initialize' do
    it 'should raise error if compilation directory is undefined' do
      opts = { node: 'foo' }
      expect { OctocatalogDiff::CatalogUtil::Command.new(opts) }.to raise_error(ArgumentError)
    end

    it 'should raise error if compilation directory is something other than a string' do
      opts = { node: 'foo', compilation_dir: [] }
      expect { OctocatalogDiff::CatalogUtil::Command.new(opts) }.to raise_error(ArgumentError)
    end

    it 'should raise error if compilation directory exists but is not a directory' do
      opts = { node: 'foo', compilation_dir: OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml') }
      expect { OctocatalogDiff::CatalogUtil::Command.new(opts) }.to raise_error(ArgumentError)
    end

    it 'should raise error if compilation directory does not exist' do
      opts = { node: 'foo', compilation_dir: OctocatalogDiff::Spec.fixture_path('facts/asldfksafdkla') }
      expect { OctocatalogDiff::CatalogUtil::Command.new(opts) }.to raise_error(Errno::ENOENT)
    end

    it 'should raise error if node is undefined' do
      opts = { compilation_dir: OctocatalogDiff::Spec.fixture_path('facts') }
      expect { OctocatalogDiff::CatalogUtil::Command.new(opts) }.to raise_error(ArgumentError)
    end

    it 'should raise error if node is not a string' do
      opts = { node: [], compilation_dir: OctocatalogDiff::Spec.fixture_path('facts') }
      expect { OctocatalogDiff::CatalogUtil::Command.new(opts) }.to raise_error(ArgumentError)
    end

    it 'should not raise error if parameters are valid' do
      opts = { node: 'foo', compilation_dir: OctocatalogDiff::Spec.fixture_path('facts') }
      expect { OctocatalogDiff::CatalogUtil::Command.new(opts) }.not_to raise_error
    end
  end

  describe '#puppet_command' do
    before(:each) do
      @compilation_dir = Dir.mktmpdir
      FileUtils.mkdir_p File.join(@compilation_dir, 'var', 'yaml', 'facts')
      @default_opts = {
        node: 'foo',
        compilation_dir: @compilation_dir,
        puppet_binary: OctocatalogDiff::Spec::PUPPET_BINARY
      }
    end

    after(:each) do
      OctocatalogDiff::Spec.clean_up_tmpdir(@compilation_dir)
    end

    let(:non_existent_file) { OctocatalogDiff::Spec.fixture_path('asldfkjadsflkajds') }
    let(:fact_file) { OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml') }
    let(:hiera_config_file) { OctocatalogDiff::Spec.fixture_path('repos/default/config/hiera.yaml') }

    it 'should raise error if puppet_binary is not supplied' do
      opts = @default_opts.dup
      opts.delete(:puppet_binary)
      testobj = OctocatalogDiff::CatalogUtil::Command.new(opts)
      expect { testobj.puppet_command }.to raise_error(ArgumentError, /Puppet binary was not supplied/)
    end

    it 'should raise error if puppet binary does not exist' do
      testobj = OctocatalogDiff::CatalogUtil::Command.new(@default_opts.merge(puppet_binary: non_existent_file))
      expect { testobj.puppet_command }.to raise_error(Errno::ENOENT, /Puppet binary.*doesn't exist/)
    end

    it 'should include --storeconfigs and --storeconfigs_backend when storeconfigs is enabled' do
      testobj = OctocatalogDiff::CatalogUtil::Command.new(@default_opts.merge(storeconfigs: true))
      result = testobj.puppet_command
      expect(result).to match(/--storeconfigs --storeconfigs_backend=puppetdb/)
    end

    it 'should include --no-storeconfigs when storeconfigs is disabled' do
      testobj = OctocatalogDiff::CatalogUtil::Command.new(@default_opts.merge(storeconfigs: false))
      result = testobj.puppet_command
      expect(result).to match(/--no-storeconfigs/)
    end

    it 'should raise error if ENC is not found' do
      testobj = OctocatalogDiff::CatalogUtil::Command.new(@default_opts.merge(enc: non_existent_file))
      expect { testobj.puppet_command }.to raise_error(Errno::ENOENT, /Did not find ENC as expected/)
    end

    it 'should include command line argument when ENC is provided' do
      enc = OctocatalogDiff::Spec.fixture_path('repos/default/config/enc.sh')
      testobj = OctocatalogDiff::CatalogUtil::Command.new(@default_opts.merge(enc: enc))
      result = testobj.puppet_command
      expect(result).to match(%r{--node_terminus=exec --external_nodes=.*/enc.sh})
    end

    it 'should not include command line argument when ENC is not provided' do
      testobj = OctocatalogDiff::CatalogUtil::Command.new(@default_opts)
      result = testobj.puppet_command
      expect(result).not_to match(/--node_terminus=exec/)
    end

    it 'should include --parser=future if that is specified' do
      testobj = OctocatalogDiff::CatalogUtil::Command.new(@default_opts.merge(parser: :future))
      result = testobj.puppet_command
      expect(result).to match(/--parser=future/)
    end

    it 'should point to factpath if facts terminus is provided and fact file is not provided' do
      testobj = OctocatalogDiff::CatalogUtil::Command.new(@default_opts)
      result = testobj.puppet_command
      expect(result).to match(%r{--factpath=.*/var/yaml/facts})
    end

    it 'should install fact file if one is provided' do
      testobj = OctocatalogDiff::CatalogUtil::Command.new(@default_opts.merge(fact_file: fact_file))
      testobj.puppet_command
      filename = File.join(@compilation_dir, 'var', 'yaml', 'facts', 'foo.yaml')
      expect(File.file?(filename)).to eq(true), filename
    end

    it 'should set facts-terminus to yaml by default' do
      testobj = OctocatalogDiff::CatalogUtil::Command.new(@default_opts)
      result = testobj.puppet_command
      expect(result).to match(/--facts_terminus=yaml/)
    end

    it 'should set facts-terminus to facter when specified' do
      testobj = OctocatalogDiff::CatalogUtil::Command.new(@default_opts.merge(facts_terminus: 'facter'))
      result = testobj.puppet_command
      expect(result).to match(/--facts_terminus=facter/)
    end

    it 'should raise error when invalid facts terminus is specified' do
      testobj = OctocatalogDiff::CatalogUtil::Command.new(@default_opts.merge(facts_terminus: 'chicken'))
      expect { testobj.puppet_command }.to raise_error(ArgumentError, /Unrecognized facts_terminus setting/)
    end

    it 'should include hiera config on command line when specified' do
      testobj = OctocatalogDiff::CatalogUtil::Command.new(@default_opts.merge(hiera_config: hiera_config_file))
      result = testobj.puppet_command
      expect(result).to match(%r{--hiera_config=.*/hiera\.yaml})
    end
  end
end
