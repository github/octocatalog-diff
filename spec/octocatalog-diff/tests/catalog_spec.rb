# frozen_string_literal: true

require_relative 'spec_helper'
require_relative '../mocks/puppetdb'

require OctocatalogDiff::Spec.require_path('/catalog')
require OctocatalogDiff::Spec.require_path('/errors')

describe OctocatalogDiff::Catalog do
  context 'backends' do
    it 'should call JSON class' do
      fixture = OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog-2.json')
      catalog_opts = { json: File.read(fixture) }
      catalog_obj = OctocatalogDiff::Catalog.new(catalog_opts)
      expect(catalog_obj.error_message).to eq(nil)
      expect(catalog_obj.catalog).to be_a_kind_of(Hash)
      expect(catalog_obj.catalog_json).to be_a_kind_of(String)
      expect(catalog_obj.catalog_json).to eq(File.read(fixture))
    end

    it 'should call puppetdb class' do
      allow(OctocatalogDiff::PuppetDB).to receive(:new) { |*_arg| OctocatalogDiff::Mocks::PuppetDB.new }
      catalog_opts = {
        puppetdb: true,
        node: 'tiny-catalog-2-puppetdb'
      }
      catalog_obj = OctocatalogDiff::Catalog.new(catalog_opts)
      catalog_obj.build
      expect(catalog_obj.error_message).to eq(nil)
      expect(catalog_obj.catalog).to be_a_kind_of(Hash)
      expect(catalog_obj.catalog_json).to be_a_kind_of(String)
      expect(catalog_obj.catalog['resources']).to be_a_kind_of(Array)
    end

    it 'should call compile class' do
      allow(OctocatalogDiff::Catalog::Computed).to receive(:new).and_return(OctocatalogDiff::Catalog::Noop.new({}))
      node = 'rspec-node.github.net'
      catalog_opts = {
        basedir: OctocatalogDiff::Spec.fixture_path('repos/tiny-repo'),
        node: node,
        puppet_binary: OctocatalogDiff::Spec::PUPPET_BINARY
      }
      catalog_obj = OctocatalogDiff::Catalog.new(catalog_opts)
      expect(catalog_obj.catalog).to eq('resources' => [])
    end

    it 'should call the noop backend' do
      catalog_opts = { backend: :noop }
      catalog_obj = OctocatalogDiff::Catalog.new(catalog_opts)
      expect(catalog_obj.builder).to eq('OctocatalogDiff::Catalog::Noop')
    end

    it 'should call the puppetmaster backend' do
      allow(OctocatalogDiff::Catalog::PuppetMaster).to receive(:new).and_return(OctocatalogDiff::Catalog::Noop.new({}))
      catalog_opts = { backend: :puppetmaster }
      catalog_obj = OctocatalogDiff::Catalog.new(catalog_opts)
      expect(catalog_obj.catalog).to eq('resources' => [])
    end

    it 'should call the puppetmaster backend when a puppet master is given' do
      allow(OctocatalogDiff::Catalog::PuppetMaster).to receive(:new).and_return(OctocatalogDiff::Catalog::Noop.new({}))
      catalog_opts = { puppet_master: 'foo.bar.baz:8140' }
      catalog_obj = OctocatalogDiff::Catalog.new(catalog_opts)
      expect(catalog_obj.catalog).to eq('resources' => [])
    end

    it 'should raise error if class is unrecognized' do
      catalog_opts = { backend: :chicken }
      expect { OctocatalogDiff::Catalog.new(catalog_opts) }.to raise_error(ArgumentError, /Unknown backend/)
    end
  end

  context 'methods' do
    context 'with successful catalog' do
      before(:each) do
        fixture = OctocatalogDiff::Spec.fixture_path('catalogs/catalog-1.json')
        catalog_opts = { json: File.read(fixture), compare_file_text: false }
        @catalog = OctocatalogDiff::Catalog.new(catalog_opts)
        @logger, @logger_string = OctocatalogDiff::Spec.setup_logger

        compiled_catalog_opts = {
          basedir: OctocatalogDiff::Spec.fixture_path('repos/tiny-repo'),
          node: 'rspec-node.github.net',
          puppet_binary: OctocatalogDiff::Spec::PUPPET_BINARY
        }
        obj = double('OctocatalogDiff::Catalog::Computed')
        allow(obj).to receive(:compilation_dir).and_return('/the/compilation/dir')
        allow(obj).to receive(:puppet_version).and_return('1.2.3.4.5')
        allow(obj).to receive(:catalog).and_return({})
        allow(obj).to receive(:catalog_json).and_return('{}')
        allow(obj).to receive(:error_message).and_return(nil)
        allow(obj).to receive(:retries).and_return(0)
        allow(OctocatalogDiff::Catalog::Computed).to receive(:new).and_return(obj)
        @compiled_catalog = OctocatalogDiff::Catalog.new(compiled_catalog_opts)
      end

      describe '#build' do
        it 'should call the #build method without arguments' do
          expect { @catalog.build }.not_to raise_error
        end

        it 'should call the #build method with a logger' do
          expect { @catalog.build(@logger) }.not_to raise_error
        end
      end

      describe '#catalog' do
        it 'should return the hash representation of the catalog' do
          @catalog.build(@logger)
          expect(@catalog.catalog).to be_a_kind_of(Hash)
          expect(@catalog.catalog['document_type']).to eq('Catalog')
        end

        it 'should auto-build the catalog' do
          expect(@catalog.catalog).to be_a_kind_of(Hash)
          expect(@catalog.catalog['document_type']).to eq('Catalog')
        end
      end

      describe '#catalog_json' do
        it 'should return the JSON representation of the catalog' do
          @catalog.build(@logger)
          expect(@catalog.catalog_json).to be_a_kind_of(String)
          expect(@catalog.catalog_json).to eq(File.read(OctocatalogDiff::Spec.fixture_path('catalogs/catalog-1.json')))
        end

        it 'should auto-build the catalog' do
          expect(@catalog.catalog_json).to be_a_kind_of(String)
          expect(@catalog.catalog_json).to eq(File.read(OctocatalogDiff::Spec.fixture_path('catalogs/catalog-1.json')))
        end
      end

      describe '#catalog_json=' do
        it 'should set the JSON representation of the catalog' do
          @catalog.catalog_json = '{"resources":[{"foo":"bar"},{"baz":"buzz"}]}'
          expect(@catalog.catalog_json).to eq('{"resources":[{"foo":"bar"},{"baz":"buzz"}]}')
        end

        it 'should cause the resource hash to be reset' do
          # Make sure the resource hash is correct now
          key = { type: 'Package', title: 'ruby' }
          resource_test = @catalog.resource(key)
          expect(resource_test).to be_a_kind_of(Hash)
          expect(resource_test['parameters']['require']).to eq('Noop[puppet/repos-configured]')

          # Modify the resource in the catalog's resource list
          res = @catalog.resources
          res.map! do |x|
            if x[:type] == 'Package' && x[:title] == 'ruby'
              x.merge('testing' => 'foobar')
            else
              x
            end
          end

          # The resource hash won't be rebuilt yet
          expect(resource_test.key?('testing')).to eq(false)

          # Rewrite the JSON, which should cause the resource hash to get rebuilt
          @catalog.catalog_json = '{"resources":[{"foo":"bar"},{"baz":"buzz"}]}'

          # Try to retrieve the resource again. It should now have the testing key.
          expect(resource_test.key?('testing')).to eq(false)
        end
      end

      describe '#compilation_dir' do
        it 'should return nil if there is no compilation directory' do
          expect(@catalog.compilation_dir).to eq(nil)
        end

        it 'should return the directory for a compiled catalog' do
          expect(@compiled_catalog.compilation_dir).to eq('/the/compilation/dir')
        end

        it 'should return the compilation directory from override' do
          @catalog.compilation_dir = '/tmp/foo/bar/baz'
          expect(@catalog.compilation_dir).to eq('/tmp/foo/bar/baz')
        end
      end

      describe '#error_message' do
        it 'should return error message from catalog compilation' do
          catalog_opts = { json: '{not json}', compare_file_text: false }
          catalog = OctocatalogDiff::Catalog.new(catalog_opts)
          expect(catalog.error_message).to match(/unexpected token at '{not json}'/)
        end

        it 'should return nil if there was no error in catalog compilation' do
          expect(@catalog.error_message).to eq(nil)
        end

        it 'should limit its output to 20,000 characters' do
          @catalog.build
          @catalog.error_message = 'x' * 21_000
          expect(@catalog.error_message.length).to eq(20_000)
        end
      end

      describe '#error_message=' do
        it 'should set the error message' do
          @catalog.build
          @catalog.error_message = 'test error'
          expect(@catalog.error_message).to eq('test error')
        end

        it 'should nil catalog and catalog_json' do
          @catalog.build
          @catalog.error_message = 'test error'
          expect(@catalog.catalog).to eq(nil)
          expect(@catalog.catalog_json).to eq(nil)
        end
      end

      describe '#puppet_version' do
        it 'should return the Puppet version passed from an option' do
          fixture = OctocatalogDiff::Spec.fixture_path('catalogs/catalog-1.json')
          catalog_opts = { json: File.read(fixture), compare_file_text: false, puppet_version: '1.2.3.4' }
          catalog = OctocatalogDiff::Catalog.new(catalog_opts)
          expect(catalog.puppet_version).to eq('1.2.3.4')
        end

        it 'should return the Puppet version used to compile a catalog' do
          expect(@compiled_catalog.puppet_version).to eq('1.2.3.4.5')
        end
      end

      describe '#resource' do
        it 'should contain known a type:title element' do
          parameters = {
            'ensure'           => 'present',
            'require'          => 'Noop[puppet/repos-configured]',
            'old-parameter'    => 'old value',
            'common-parameter' => 'old value'
          }
          result = @catalog.resource(type: 'Package', title: 'rubygems1.8')
          expect(result).to be_a_kind_of(Hash)
          expect(result['parameters']).to eq(parameters)
        end

        it 'should return nil when an unknown type:title element is passed' do
          result = @catalog.resource(type: 'aasdfasfdsfdf', title: 'asdffsadfasdfadsfsdf')
          expect(result).to eq(nil)
        end
      end

      describe '#resources' do
        it 'should have a non-empty array of resources' do
          result = @catalog.resources
          expect(result).to be_a_kind_of(Array)
          expect(result.size).to be > 0
        end
      end

      describe '#retries' do
        it 'should return nil if the backend does not support retries' do
          expect(@catalog.retries).to eq(nil)
        end

        it 'should return the actual number of retries' do
          expect(@compiled_catalog.retries).to eq(0)
        end
      end

      describe '#valid?' do
        it 'should be true if catalog compilation succeeded' do
          fixture = OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog-2.json')
          catalog_opts = { json: File.read(fixture) }
          catalog = OctocatalogDiff::Catalog.new(catalog_opts)
          expect(catalog.valid?).to eq(true)
        end
      end
    end

    context 'with failed catalog' do
      before(:each) do
        compiled_catalog_opts = {
          basedir: OctocatalogDiff::Spec.fixture_path('repos/tiny-repo'),
          node: 'rspec-node.github.net',
          puppet_binary: OctocatalogDiff::Spec::PUPPET_BINARY
        }
        obj = double('OctocatalogDiff::Catalog::Computed')
        allow(obj).to receive(:compilation_dir).and_return('/the/compilation/dir')
        allow(obj).to receive(:puppet_version).and_return('1.2.3.4.5')
        allow(obj).to receive(:catalog).and_return(nil)
        allow(obj).to receive(:catalog_json).and_return(nil)
        allow(obj).to receive(:error_message).and_return('Broken!')
        allow(obj).to receive(:retries).and_return(0)
        allow(OctocatalogDiff::Catalog::Computed).to receive(:new).and_return(obj)
        @catalog = OctocatalogDiff::Catalog.new(compiled_catalog_opts)
      end

      describe '#catalog' do
        it 'should be nil' do
          expect(@catalog.catalog).to eq(nil)
        end
      end

      describe '#catalog_json' do
        it 'should be nil' do
          expect(@catalog.catalog_json).to eq(nil)
        end
      end

      describe '#error_message' do
        it 'should contain the text of the error' do
          expect(@catalog.error_message).to match(/Broken!/)
        end
      end

      describe '#resource' do
        it 'should raise error' do
          expect do
            @catalog.resource(type: 'System::User', title: 'alice')
          end.to raise_error(OctocatalogDiff::Errors::CatalogError, /Broken!/)
        end
      end

      describe '#resources' do
        it 'should throw an error' do
          expect do
            @catalog.resources
          end.to raise_error(OctocatalogDiff::Errors::CatalogError, /Broken!/)
        end
      end

      describe '#valid?' do
        it 'should be false if catalog compilation failed' do
          expect(@catalog.valid?).to eq(false)
        end
      end
    end
  end

  context 'file conversions' do
    before(:each) do
      @tmpdir = Dir.mktmpdir
      FileUtils.cp_r OctocatalogDiff::Spec.fixture_path('repos/tiny-repo/modules'), @tmpdir
      Dir.mkdir File.join(@tmpdir, 'environments')
      File.symlink @tmpdir, File.join(@tmpdir, 'environments', 'production')
    end

    after(:each) do
      FileUtils.remove_entry_secure @tmpdir if File.directory?(@tmpdir)
    end

    context 'under Puppet 3.x' do
      describe '#initialize' do
        it 'should convert file source to content when :compare_file_text is true' do
          opts = {
            compare_file_text: true,
            node: 'my.rspec.node',
            basedir: @tmpdir,
            json: File.read(OctocatalogDiff::Spec.fixture_path('catalogs/catalog-test-file.json'))
          }
          catalog = OctocatalogDiff::Catalog.new(opts)
          result = catalog.resources.select { |x| x['type'] == 'File' && x['title'] == '/tmp/foo' }
          expect(result.size).to eq(1)
          expect(result.first['parameters'].key?('source')).to eq(false), result.to_json
          expect(result.first['parameters']['content']).to eq("foo\n"), result.to_json
        end

        it 'should not convert file source to content when :compare_file_text is false' do
          opts = {
            compare_file_text: false,
            node: 'my.rspec.node',
            basedir: @tmpdir,
            json: File.read(OctocatalogDiff::Spec.fixture_path('catalogs/catalog-test-file.json'))
          }
          catalog = OctocatalogDiff::Catalog.new(opts)
          result = catalog.resources.select { |x| x['type'] == 'File' && x['title'] == '/tmp/foo' }
          expect(result.size).to eq(1)
          expect(result.first['parameters'].key?('content')).to eq(false), result.to_json
          expect(result.first['parameters']['source']).to eq('puppet:///modules/test/tmp/foo'), result.to_json
        end
      end
    end

    context 'under Puppet 4.x' do
      describe '#initialize' do
        it 'should convert file source to content when :compare_file_text is true' do
          opts = {
            compare_file_text: true,
            node: 'my.rspec.node',
            basedir: @tmpdir,
            json: File.read(OctocatalogDiff::Spec.fixture_path('catalogs/catalog-test-file-v4.json'))
          }
          catalog = OctocatalogDiff::Catalog.new(opts)
          result = catalog.resources.select { |x| x['type'] == 'File' && x['title'] == '/tmp/foo' }
          expect(result.size).to eq(1)
          expect(result.first['parameters'].key?('source')).to eq(false), result.to_json
          expect(result.first['parameters']['content']).to eq("foo\n"), result.to_json
        end

        it 'should not convert file source to content when :compare_file_text is false' do
          opts = {
            compare_file_text: false,
            node: 'my.rspec.node',
            basedir: @tmpdir,
            json: File.read(OctocatalogDiff::Spec.fixture_path('catalogs/catalog-test-file-v4.json'))
          }
          catalog = OctocatalogDiff::Catalog.new(opts)
          result = catalog.resources.select { |x| x['type'] == 'File' && x['title'] == '/tmp/foo' }
          expect(result.size).to eq(1)
          expect(result.first['parameters'].key?('content')).to eq(false), result.to_json
          expect(result.first['parameters']['source']).to eq('puppet:///modules/test/tmp/foo'), result.to_json
        end
      end
    end
  end
end

describe OctocatalogDiff::Catalog do
  describe '#resources_missing_from_catalog' do
    let(:catalog) do
      opts = {
        compare_file_text: false,
        node: 'my.rspec.node',
        json: File.read(OctocatalogDiff::Spec.fixture_path('catalogs/tiny-catalog.json'))
      }
      OctocatalogDiff::Catalog.new(opts)
    end

    it 'should raise error if resource is not in expected format' do
      test_arg = ['Foo-Bar']
      expect { catalog.send(:resources_missing_from_catalog, test_arg) }.to raise_error(ArgumentError, /Resource Foo-Bar /)
    end

    it 'should return full array when no matches' do
      allow(catalog).to receive(:resource).with(type: 'Foo', title: 'bar').and_return(nil)
      allow(catalog).to receive(:resource).with(type: 'Baz', title: 'biff').and_return(nil)
      test_arg = ['Foo[bar]', 'Baz[biff]']
      result = catalog.send(:resources_missing_from_catalog, test_arg)
      expect(result).to eq(['Foo[bar]', 'Baz[biff]'])
    end

    it 'should remove matching entries' do
      allow(catalog).to receive(:resource).with(type: 'Foo', title: 'bar').and_return(nil)
      allow(catalog).to receive(:resource).with(type: 'Baz', title: 'biff').and_return(true)
      test_arg = ['Foo[bar]', 'Baz[biff]']
      result = catalog.send(:resources_missing_from_catalog, test_arg)
      expect(result).to eq(['Foo[bar]'])
    end

    it 'should return empty array with all matches' do
      allow(catalog).to receive(:resource).with(type: 'Foo', title: 'bar').and_return(true)
      allow(catalog).to receive(:resource).with(type: 'Baz', title: 'biff').and_return(true)
      test_arg = ['Foo[bar]', 'Baz[biff]']
      result = catalog.send(:resources_missing_from_catalog, test_arg)
      expect(result).to eq([])
    end
  end

  describe '#validate_references' do
    it 'should return nil if no reference validation is requested' do
      opts = {
        compare_file_text: false,
        node: 'my.rspec.node',
        json: File.read(OctocatalogDiff::Spec.fixture_path('catalogs/reference-validation-broken.json'))
      }
      catalog = OctocatalogDiff::Catalog.new(opts)
      result = catalog.validate_references
      expect(result).to be_nil
    end

    it 'should raise error if reference validation is requested' do
      opts = {
        compare_file_text: false,
        validate_references: %w(before notify require subscribe),
        node: 'my.rspec.node',
        json: File.read(OctocatalogDiff::Spec.fixture_path('catalogs/reference-validation-broken.json'))
      }
      catalog = OctocatalogDiff::Catalog.new(opts)
      error_str = [
        'Catalog has broken references: exec[subscribe caller 1] -> subscribe[Exec[subscribe target]]',
        'exec[subscribe caller 2] -> subscribe[Exec[subscribe target]]',
        'exec[subscribe caller 2] -> subscribe[Exec[subscribe target 2]]',
        'exec[subscribe caller 3] -> subscribe[Exec[subscribe target]]'
      ].join('; ')
      expect { catalog.validate_references }.to raise_error(OctocatalogDiff::Errors::ReferenceValidationError, error_str)
    end
  end

  describe '#build_resource_hash' do
    before(:each) do
      resource_array = [
        {
          'type' => 'Exec',
          'title' => 'title of the exec',
          'file' => '/etc/puppetlabs/code/site/manifests/init.pp',
          'line' => 6,
          'exported' => false,
          'parameters' => {
            'alias' => 'the exec',
            'command' => '/bin/true'
          }
        }
      ]
      described_object = described_class.allocate
      expect(described_object).to receive(:resources).and_return(resource_array)
      described_object.send(:build_resource_hash)
      @resource_hash = described_object.instance_variable_get(:'@resource_hash')
    end

    it 'should contain the entry for the titled resource' do
      expect(@resource_hash['Exec']['title of the exec']).to be_a_kind_of(Hash)
    end

    it 'should contain the entry for the aliased resource' do
      expect(@resource_hash['Exec']['the exec']).to be_a_kind_of(Hash)
    end
  end
end
