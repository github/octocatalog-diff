# frozen_string_literal: true

require_relative '../spec_helper'
require OctocatalogDiff::Spec.require_path('/catalog')
require OctocatalogDiff::Spec.require_path('/catalog-diff/differ')
require OctocatalogDiff::Spec.require_path('/errors')
require 'json'

# Read this about the fixtures:
# - catalog-1.json is a partial catalog from an actual run (manually truncated to save time).
# - catalog-2.json is a copy of catalog-1.json, with changes made to create test cases.
# Note that neither of these would probably actually work if applied with Puppet.
# However since this code is testing the diff engine, actual Puppet functionality isn't required.

describe OctocatalogDiff::CatalogDiff::Differ do
  VERSIONS = {
    'puppet 3.x' => {
      json_1: OctocatalogDiff::Spec.fixture_path('catalogs/catalog-1.json'),
      json_2: OctocatalogDiff::Spec.fixture_path('catalogs/catalog-2.json')
    },
    'puppet 4.x' => {
      json_1: OctocatalogDiff::Spec.fixture_path('catalogs/catalog-1-v4.json'),
      json_2: OctocatalogDiff::Spec.fixture_path('catalogs/catalog-2-v4.json')
    },
    'puppet 3.x vs 4.x' => {
      json_1: OctocatalogDiff::Spec.fixture_path('catalogs/catalog-1.json'),
      json_2: OctocatalogDiff::Spec.fixture_path('catalogs/catalog-2-v4.json')
    }
  }.freeze

  VERSIONS.each do |tag, files|
    context tag do
      before(:all) do
        empty_puppet_catalog_json = File.read(OctocatalogDiff::Spec.fixture_path('catalogs/catalog-empty.json'))
        @empty_puppet_catalog = OctocatalogDiff::Catalog.create(json: empty_puppet_catalog_json)

        @puppet_catalog_json_text = File.read(files[:json_1])
        @puppet_catalog_json = OctocatalogDiff::Catalog.create(json: @puppet_catalog_json_text)

        @puppet_catalog_parsed_json_text = JSON.parse(@puppet_catalog_json_text)
        @puppet_catalog_parsed_json = OctocatalogDiff::Catalog.create(json: JSON.generate(@puppet_catalog_parsed_json_text))

        @puppet_catalog_json_2_text = File.read(files[:json_2])
        @puppet_catalog_json_2 = OctocatalogDiff::Catalog.create(json: @puppet_catalog_json_2_text)

        @puppet_catalog_parsed_json_2 = OctocatalogDiff::Catalog.create(json: @puppet_catalog_json_2_text)

        @options = {}
      end

      describe '#new' do
        it 'should convert a catalog JSON string to array of resources' do
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(@options, @puppet_catalog_json, @empty_puppet_catalog)
          expect(testobj.diff).to be_a_kind_of(Array)
        end

        it 'should pass through a valid hash as array of resources' do
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(@options, @puppet_catalog_parsed_json, @empty_puppet_catalog)
          expect(testobj.diff).to be_a_kind_of(Array)
        end

        it 'should raise exception when something other than a catalog is passed in' do
          expect do
            OctocatalogDiff::CatalogDiff::Differ.new(@options, 'This is not a catalog!', @empty_puppet_catalog)
          end.to raise_error(OctocatalogDiff::Errors::DifferError)
        end
      end

      describe '#ignore' do
        it 'should filter out one type' do
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(@options, @puppet_catalog_parsed_json, @empty_puppet_catalog)
          testobj.ignore(type: 'File')
          result = testobj.diff
          expect(OctocatalogDiff::Spec.count_by_type(result, 'File')).to eq(0)
          expect(OctocatalogDiff::Spec.count_by_type(result, 'Class')).not_to eq(0)
          expect(OctocatalogDiff::Spec.count_by_type(result, 'Stage')).not_to eq(0)
        end

        it 'should filter out multiple types' do
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(@options, @puppet_catalog_parsed_json, @empty_puppet_catalog)
          testobj.ignore([{ type: 'File' }, { type: 'Class' }])
          result = testobj.diff
          expect(OctocatalogDiff::Spec.count_by_type(result, 'File')).to eq(0)
          expect(OctocatalogDiff::Spec.count_by_type(result, 'Class')).to eq(0)
          expect(OctocatalogDiff::Spec.count_by_type(result, 'Stage')).not_to eq(0)
        end

        it 'should filter out a provided type + title combination' do
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(@options, @puppet_catalog_parsed_json, @empty_puppet_catalog)
          testobj.ignore(type: 'File', title: '/usr/bin/npm')
          result = testobj.diff
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/npm')).to eq(false)
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/node-waf')).to eq(true)
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/node')).to eq(true)
        end

        it 'should filter out multiple provided type + title combinations' do
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(@options, @puppet_catalog_parsed_json, @empty_puppet_catalog)
          testobj.ignore([{ type: 'File', title: '/usr/bin/npm' }, { type: 'File', title: '/usr/bin/node-waf' }])
          result = testobj.diff
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/npm')).to eq(false)
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/node-waf')).to eq(false)
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/node')).to eq(true)
        end

        it 'should ignore due to wildcards at the end of titles' do
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(@options, @puppet_catalog_parsed_json, @empty_puppet_catalog)
          testobj.ignore(type: 'File', title: '/usr/bin/no*')
          result = testobj.diff
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/npm')).to eq(true)
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/node-waf')).to eq(false)
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/node')).to eq(false)
        end

        it 'should ignore due to wildcards in the middle of titles' do
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(@options, @puppet_catalog_parsed_json, @empty_puppet_catalog)
          testobj.ignore(type: 'File', title: '/usr/bin/n*e')
          result = testobj.diff
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/npm')).to eq(true)
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/node-waf')).to eq(true)
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/node')).to eq(false)
        end

        it 'should ignore title when wildcard matches 0 characters' do
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(@options, @puppet_catalog_parsed_json, @empty_puppet_catalog)
          testobj.ignore(type: 'File', title: '/usr/bin/node*')
          result = testobj.diff
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/npm')).to eq(true)
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/node-waf')).to eq(false)
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/node')).to eq(false)
        end

        it 'should ignore due to 2 wildcards in same expression' do
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(@options, @puppet_catalog_parsed_json, @empty_puppet_catalog)
          testobj.ignore(type: 'File', title: '/usr/bin/no*-*')
          result = testobj.diff
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/npm')).to eq(true)
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/node-waf')).to eq(false)
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/node')).to eq(true)
        end

        it 'should ignore wildcard titles in all types' do
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(@options, @puppet_catalog_parsed_json, @empty_puppet_catalog)
          testobj.ignore(type: '*', title: '/usr/bin/no*')
          result = testobj.diff
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/npm')).to eq(true)
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/node-waf')).to eq(false)
          expect(OctocatalogDiff::Spec.contains_type_and_title?(result, 'file', '/usr/bin/node')).to eq(false)
        end

        it 'should filter out one top level ignored attribute' do
          r1 = [
            {
              'type'       => 'File',
              'title'      => '/etc/puppet/puppet.conf',
              'tags'       => ['file', 'class', 'puppet::agent', 'puppet', 'agent'],
              'file'       => '/environments/production/modules/puppet/manifests/agent.pp',
              'line'       => 46,
              'foo'        => 'bar',
              'parameters' => {
                'ensure'   => 'present',
                'owner'    => 'root',
                'group'    => 'root',
                'mode'     => '0444',
                'content'  => '# THIS FILE IS AUTOMATICALLY DISTRIBUTED BY PUPPET.',
                'backup'   => false
              }
            }
          ]

          r2 = OctocatalogDiff::Spec.deep_copy(r1)
          r2[0]['foo'] = 'baz'
          r2[0]['parameters']['mode'] = '0755'

          cat1 = OctocatalogDiff::Spec.build_catalog(r1)
          cat2 = OctocatalogDiff::Spec.build_catalog(r2)
          logger, logger_str = OctocatalogDiff::Spec.setup_logger
          opts = { logger: logger }
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, cat1, cat2)
          testobj.ignore(attr: 'foo')
          result = testobj.diff
          expect(result.size).to eq(1)
          expect(result.first[0]).to eq('~')
          expect(result.first[1]).to eq("File\f/etc/puppet/puppet.conf\fparameters\fmode")
          expect(logger_str.string).to match(/Entering hashdiff_initial; catalog sizes: 1, 1/)
          expect(logger_str.string).to match(/Exiting hashdiff_initial; changes: 2, nested changes: 0/)
          expect(logger_str.string).to match(%r{:type=>"File", :title=>"/etc/puppet/puppet.conf", :attr=>"foo"})
          expect(logger_str.string).to match(/Exiting catdiff; change count: 1/)
        end

        it 'should filter out multiple ignored attributes' do
          r1 = [
            {
              'type'       => 'File',
              'title'      => '/etc/puppet/puppet.conf',
              'tags'       => ['file', 'class', 'puppet::agent', 'puppet', 'agent'],
              'file'       => '/environments/production/modules/puppet/manifests/agent.pp',
              'line'       => 46,
              'foo'        => 'bar',
              'fizz'       => 'buzz',
              'parameters' => {
                'ensure'   => 'present',
                'owner'    => 'root',
                'group'    => 'root',
                'mode'     => '0444',
                'content'  => '# THIS FILE IS AUTOMATICALLY DISTRIBUTED BY PUPPET.',
                'backup'   => false
              }
            }
          ]

          r2 = OctocatalogDiff::Spec.deep_copy(r1)
          r2[0]['foo'] = 'baz'
          r2[0]['fizz'] = 'bazz'
          r2[0]['parameters']['mode'] = '0755'

          cat1 = OctocatalogDiff::Spec.build_catalog(r1)
          cat2 = OctocatalogDiff::Spec.build_catalog(r2)
          logger, logger_str = OctocatalogDiff::Spec.setup_logger
          opts = { logger: logger }
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, cat1, cat2)
          testobj.ignore(attr: 'foo')
          testobj.ignore(attr: 'parameters')
          result = testobj.diff
          expect(result.size).to eq(1)
          expect(result.first[0]).to eq('~')
          expect(result.first[1]).to eq("File\f/etc/puppet/puppet.conf\ffizz")
          expect(logger_str.string).to match(/Entering hashdiff_initial; catalog sizes: 1, 1/)
          expect(logger_str.string).to match(/Exiting hashdiff_initial; changes: 3, nested changes: 0/)
          expect(logger_str.string).to match(%r{:type=>"File", :title=>"/etc/puppet/puppet.conf", :attr=>"foo"})
          expect(logger_str.string).to match(%r{:type=>"File", :title=>"/etc/puppet/puppet.conf", :attr=>"parameters\\fmode})
          expect(logger_str.string).to match(/Exiting catdiff; change count: 1/)
        end

        it 'should filter out an attribute at the beginning, middle, and end' do
          r1 = [
            {
              'type'       => 'File',
              'title'      => '/etc/puppet/puppet.conf',
              'tags'       => ['file', 'class', 'puppet::agent', 'puppet', 'agent'],
              'file'       => '/environments/production/modules/puppet/manifests/agent.pp',
              'line'       => 46,
              'fizz'       => 'buzz',
              'parameters' => {
                'ensure'   => 'present',
                'owner'    => 'root',
                'group'    => 'root',
                'mode'     => '0444',
                'content'  => '# THIS FILE IS AUTOMATICALLY DISTRIBUTED BY PUPPET.',
                'backup'   => false,
                'fizz'     => { 'buzz' => false },
                'buzz'     => { 'fizz' => true }
              }
            }
          ]

          r2 = OctocatalogDiff::Spec.deep_copy(r1)
          r2[0]['fizz'] = 'bazz'
          r2[0]['parameters']['mode'] = '0755'
          r2[0]['parameters']['fizz'] = { 'buzz' => true }
          r2[0]['parameters']['buzz'] = { 'fizz' => false }

          cat1 = OctocatalogDiff::Spec.build_catalog(r1)
          cat2 = OctocatalogDiff::Spec.build_catalog(r2)
          logger, logger_str = OctocatalogDiff::Spec.setup_logger
          opts = { logger: logger }
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, cat1, cat2)
          testobj.ignore(attr: 'fizz')
          result = testobj.diff
          expect(result.size).to eq(1)
          expect(result.first[0]).to eq('~')
          expect(result.first[1]).to eq("File\f/etc/puppet/puppet.conf\fparameters\fmode")
          expect(logger_str.string).to match(/Entering hashdiff_initial; catalog sizes: 1, 1/)
          expect(logger_str.string).to match(/Exiting hashdiff_initial; changes: 4, nested changes: 0/)
          expect(logger_str.string).to match(%r{:type=>"File", :title=>"/etc/puppet/puppet.conf", :attr=>"fizz"})
          expect(logger_str.string).to match(%r{:title=>"/etc/puppet/puppet.conf", :attr=>"parameters\\ffizz\\fbuzz})
          expect(logger_str.string).to match(%r{:title=>"/etc/puppet/puppet.conf", :attr=>"parameters\\fbuzz\\ffizz})
          expect(logger_str.string).to match(/Exiting catdiff; change count: 1/)
        end

        it 'should filter out a complex attribute' do
          r1 = [
            {
              'type' => 'Example1', 'title' => 'main', 'tags' => ['stage'], 'exported' => false,
              'parameters' => {
                'name' => 'main', 'toplevel' => 'toplevel attribute',
                'nest' => {
                  'toplevel' => 'toplevel_nest attribute',
                  'nest' => { 'nest' => 'nested nested text' },
                  'nest2' => { 'chicken' => 'egg' },
                  'chicken' => 'egg'
                }
              }
            }
          ]

          r2 = OctocatalogDiff::Spec.deep_copy(r1)
          r2[0]['parameters']['toplevel'] = 'new toplevel attribute'
          r2[0]['parameters']['nest']['toplevel'] = 'new toplevel_nest attribute'

          cat1 = OctocatalogDiff::Spec.build_catalog(r1)
          cat2 = OctocatalogDiff::Spec.build_catalog(r2)
          logger, logger_str = OctocatalogDiff::Spec.setup_logger
          opts = { logger: logger }
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, cat1, cat2)
          testobj.ignore(attr: "parameters\fnest\ftoplevel")
          result = testobj.diff
          expect(result.size).to eq(1), result.inspect
          expect(result.first[0]).to eq('~')
          expect(result.first[1]).to eq("Example1\fmain\fparameters\ftoplevel")
          expect(logger_str.string).to match(/Entering hashdiff_initial; catalog sizes: 1, 1/)
          expect(logger_str.string).to match(/Exiting hashdiff_initial; changes: 2, nested changes: 0/)
          expect(logger_str.string).to match(/:type=>"Example1", :title=>"main", :attr=>"parameters\\fnest\\ftoplevel"/)
          expect(logger_str.string).to match(/Exiting catdiff; change count: 1/)
        end

        it 'should contain the test objects used below' do
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(@options, @puppet_catalog_parsed_json, @empty_puppet_catalog)
          result = testobj.diff
          answer1 = ['-', "Class\fGithub::XYZclass"]
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, answer1)).to eq(true)
          answer2 = ['-', "Package\fruby"]
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, answer2)).to eq(true)
          answer3 = ['-', "Apt::Pin\fopenssl"]
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, answer3)).to eq(true)
        end

        it 'should filter out one ignored item' do
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(@options, @puppet_catalog_parsed_json, @empty_puppet_catalog)
          testobj.ignore(type: 'Package', title: 'ruby')
          result = testobj.diff
          answer1 = ['-', "Class\fGithub::XYZclass"]
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, answer1)).to eq(true)
          answer2 = ['-', "Package\fruby"]
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, answer2)).to eq(false)
          answer3 = ['-', "Apt::Pin\fopenssl"]
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, answer3)).to eq(true)
        end

        it 'should filter out multiple ignored items' do
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(@options, @puppet_catalog_parsed_json, @empty_puppet_catalog)
          ignores = [
            { type: 'Package', title: 'ruby' },
            { type: 'Apt::Pin', title: 'openssl' }
          ]
          testobj.ignore(ignores)
          result = testobj.diff
          answer1 = ['-', "Class\fGithub::XYZclass"]
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, answer1)).to eq(true)
          answer2 = ['-', "Package\fruby"]
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, answer2)).to eq(false)
          answer3 = ['-', "Apt::Pin\fopenssl"]
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, answer3)).to eq(false)
        end

        it 'should raise error if ignore does not contain :type, :title, or :attr' do
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(@options, @puppet_catalog_parsed_json, @empty_puppet_catalog)
          expect { testobj.ignore(foo: 'bar') }.to raise_error(ArgumentError, /does not contain :type, :title, or :attr/)
        end
      end

      describe '#filter_and_cleanup' do
        it 'should convert file resource titles' do
          json_hash = {
            'document_type' => 'Catalog',
            'data' => {
              'name' => 'rspec-node.github.net',
              'tags' => [],
              'resources' => [
                {
                  'type' => 'File',
                  'title' => 'dfjlkasdfjkalsfjlkadsfjklsdfjads',
                  'parameters' => {
                    'path' => '/etc/foo'
                  }
                }
              ]
            }
          }
          catalog = OctocatalogDiff::Catalog.create(json: JSON.generate(json_hash))
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(@options, catalog, @empty_puppet_catalog)
          result = testobj.catalog1
          expect(result.first['title']).to eq('/etc/foo')
        end

        it 'should hide sensitive parameters' do
          json_hash = {
            'document_type' => 'Catalog',
            'data' => {
              'name' => 'rspec-node.github.net',
              'tags' => [],
              'resources' => [
                {
                  'type' => 'File',
                  'title' => 'verysecretfile',
                  'parameters' => {
                    'content' => 'secret1'
                  },
                  'sensitive_parameters' => ['content']
                }
              ]
            }
          }
          catalog = OctocatalogDiff::Catalog.create(json: JSON.generate(json_hash))
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(@options, catalog, @empty_puppet_catalog)
          result = testobj.catalog1
          expect(result.first['parameters']['content']).to eq('Sensitive [md5sum 05183a01bf8570c7691fc4e362998f3d]')
        end
      end

      describe '#diff' do
        it 'should return no differences when a catalog is compared to itself' do
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(@options, @puppet_catalog_parsed_json, @puppet_catalog_parsed_json)
          result = testobj.diff
          expect(result).to be_a_kind_of(Array)
          expect(result.size).to eq(0)
        end

        context 'Comparing two known catalogs' do
          before(:all) do
            logger, logger_str = OctocatalogDiff::Spec.setup_logger
            options = { logger: logger }
            testobj = OctocatalogDiff::CatalogDiff::Differ.new(
              options,
              @puppet_catalog_parsed_json,
              @puppet_catalog_parsed_json_2
            )
            testobj.ignore(attr: 'tags')
            @result = testobj.diff
            @logs = logger_str.string
          end

          # Ensure that the number of diffs is as expected - if there are more diffs here than
          # expected, something is wrong.
          it 'should have the correct number of diffs' do
            expect(@result.size).to eq(17)
          end

          # Make sure line numbers or manifest files aren't seen as differences.
          # The file name and line numbers for the resource in the regexp below are different
          # between the two catalogs.
          it 'should not consider changes to manifest file or line number to be diffs' do
            found_result = @result.select { |x| x[1] =~ /^Ruby::Install\free-1.8.7-2012.02\+github1/ }
            expect(found_result.size).to eq(0)
          end

          # Differences 1-2
          it 'should detect a removed parameter even when a new parameter was added at the same level' do
            answer_map = {
              'file' => '/environments/production/modules/ruby/manifests/system.pp',
              'line' => 27
            }
            answer1 = ['!', "Package\frubygems1.8\fparameters\fold-parameter", 'old value', nil, answer_map, answer_map]
            answer2 = ['!', "Package\frubygems1.8\fparameters\fnew-parameter", nil, 'new value', answer_map, answer_map]
            expect(@result).to include(answer1)
            expect(@result).to include(answer2)
          end

          # Difference 3
          it 'should detect adding elements to a common array' do
            loc_map = { 'file' => nil, 'line' => nil } # This is a class, file/line isn't provided
            answer = ['!', "Class\fOpenssl::Package\fparameters\fcommon-array", [1, 3, 5], [1, 2, 3, 4, 5], loc_map, loc_map]
            expect(@result).to include(answer)
          end

          # Difference 4
          it 'should detect adding a new key to an existing hash whose value is an array' do
            loc_map = { 'file' => '/environments/production/modules/nodejs/manifests/init.pp', 'line' => 24 }
            answer = ['!', "Package\fnpm\fparameters\fonly-in-new", nil, %w(foo bar baz), loc_map, loc_map]
            expect(@result).to include(answer)
          end

          # Difference 5
          it 'should detect removing a key from an existing hash whose value is an array' do
            loc_map = { 'file' => '/environments/production/modules/nodejs/manifests/init.pp', 'line' => 28 }
            answer = ['!', "Package\fnvm-0.8.11\fparameters\fonly-in-old", %w(FOO BAR BAZ), nil, loc_map, loc_map]
            expect(@result).to include(answer)
          end

          # Difference 6
          it 'should detect adding a key to an new hash whose value is a string' do
            loc_map = { 'file' => '/environments/production/modules/ruby/manifests/system.pp', 'line' => 27 }
            answer = ['!', "Package\fruby1.8-dev\fparameters\fnew-parameter", nil, 'new value', loc_map, loc_map]
            expect(@result).to include(answer)
          end

          # Difference 7
          it 'should detect removing a key from an existing hash whose value is a string' do
            loc_map = { 'file' => '/environments/production/modules/ruby/manifests/system.pp', 'line' => 27 }
            answer = ['!', "Package\fruby1.8-dev\fparameters\fold-parameter", 'old value', nil, loc_map, loc_map]
            expect(@result).to include(answer)
          end

          # Difference 8
          it 'should detect a new resource only existing in the new catalog' do
            answer = ['+', "Class\fmain-this-is-new"]
            expect(OctocatalogDiff::Spec.array_contains_partial_array?(@result, answer)).to eq(true)
          end

          # Difference 9
          it 'should detect removing a resource from a catalog' do
            answer = ['-', "Class\fmain-this-is-old"]
            expect(OctocatalogDiff::Spec.array_contains_partial_array?(@result, answer)).to eq(true)
          end

          # Difference 10
          it 'should detect a change to content of a file between catalogs' do
            found_result = @result.select { |x| x[0] == '~' && x[1] == "File\f/etc/puppet/puppet.conf\fparameters\fcontent" }
            expect(found_result.size).to eq(1)
            expect(found_result.first[2]).to match(/hello world old file/)
            expect(found_result.first[3]).to match(/hello world new file/)
            loc_map = { 'file' => '/environments/production/modules/puppet/manifests/agent.pp', 'line' => 46 }
            expect(found_result.first[4]).to eq(loc_map)
          end

          # Difference 11
          it 'should detect a simple string parameter change' do
            loc_map = { 'file' => '/environments/production/modules/ruby/manifests/system.pp', 'line' => 27 }
            answer = ['~', "Package\frubygems1.8\fparameters\fcommon-parameter", 'old value', 'new value', loc_map, loc_map]
            expect(@result).to include(answer)
          end

          # Difference 12
          it 'should detect a simple string change that is not under parameters' do
            loc_map = { 'file' => '/environments/production/modules/ruby/manifests/init.pp', 'line' => 27 }
            answer = ['~', "Ruby::Install\f1.8.7-p357/present\fexported", 'old', 'new', loc_map, loc_map]
            expect(@result).to include(answer)
          end

          # Difference 13
          it 'should handle integers as values' do
            loc_map = { 'file' => '/environments/production/modules/nodejs/manifests/init.pp', 'line' => 37 }
            answer = ['~', "File\f/usr/bin/node\fparameters\fnumero", 4, 1, loc_map, loc_map]
            expect(@result).to include(answer)
          end

          # Differences 14-15
          it 'should detect a changed parameter plus an added parameter' do
            loc_map = { 'file' => '/environments/production/modules/nodejs/manifests/init.pp', 'line' => 55 }
            path = '/usr/share/nvm/0.8.11/bin/node-waf'
            answer1 = ['~', "File\f/usr/bin/node-waf\fparameters\fensure", path, 'link', loc_map, loc_map]
            answer2 = ['!', "File\f/usr/bin/node-waf\fparameters\ftarget", nil, path, loc_map, loc_map]
            expect(@result).to include(answer1)
            expect(@result).to include(answer2)
          end

          # Differences 16-17
          it 'should detect a changed parameter plus a removed parameter' do
            loc_map = { 'file' => '/environments/production/modules/nodejs/manifests/init.pp', 'line' => 46 }
            path = '/usr/share/nvm/0.8.11/bin/npm'
            answer1 = ['~', "File\f/usr/bin/npm\fparameters\fensure", 'link', path, loc_map, loc_map]
            answer2 = ['!', "File\f/usr/bin/npm\fparameters\ftarget", path, nil, loc_map, loc_map]
            expect(@result).to include(answer1)
            expect(@result).to include(answer2)
          end
        end
      end
    end
  end
end

describe OctocatalogDiff::CatalogDiff::Differ do
  context 'ignoring only adds / removes / changes' do
    describe '#ignore' do
      before(:all) do
        @c1 = OctocatalogDiff::Catalog.create(json: OctocatalogDiff::Spec.fixture_read('catalogs/ignore-add-remove-1.json'))
        @c2 = OctocatalogDiff::Catalog.create(json: OctocatalogDiff::Spec.fixture_read('catalogs/ignore-add-remove-2.json'))
        @add_answer_content = [
          '+',
          "File\f/tmp/added",
          {
            'type' => 'File',
            'title' => '/tmp/added',
            'exported' => false,
            'parameters' => {
              'mode' => '0755'
            }
          }
        ]
        @removed_answer_content = [
          '-',
          "File\f/tmp/removed",
          {
            'type' => 'File',
            'title' => '/tmp/removed',
            'exported' => false,
            'parameters' => {
              'mode' => '0755'
            }
          }
        ]
        @changed_answer_content = [
          '~',
          "File\f/tmp/changed\fparameters\fmode",
          '0444',
          '0755'
        ]
      end

      it 'should detect all changes with no ignores' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        result = testobj.diff
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @add_answer_content)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @removed_answer_content)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @changed_answer_content)).to eq(true)
      end

      it 'should filter out additions' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        testobj.ignore(type: 'File', title: '/tmp/*', attr: '+')
        result = testobj.diff
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @add_answer_content)).to eq(false)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @removed_answer_content)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @changed_answer_content)).to eq(true)
      end

      it 'should filter out removals' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        testobj.ignore(type: 'File', title: '/tmp/*', attr: '-')
        result = testobj.diff
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @add_answer_content)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @removed_answer_content)).to eq(false)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @changed_answer_content)).to eq(true)
      end

      it 'should filter out changes' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        testobj.ignore(type: 'File', title: '/tmp/*', attr: '~')
        result = testobj.diff
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @add_answer_content)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @removed_answer_content)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @changed_answer_content)).to eq(false)
      end

      it 'should filter out additions and removals with +-' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        testobj.ignore(type: 'File', title: '/tmp/*', attr: '+-')
        result = testobj.diff
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @add_answer_content)).to eq(false)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @removed_answer_content)).to eq(false)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @changed_answer_content)).to eq(true)
      end

      it 'should filter out additions and removals with -+' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        testobj.ignore(type: 'File', title: '/tmp/*', attr: '-+')
        result = testobj.diff
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @add_answer_content)).to eq(false)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @removed_answer_content)).to eq(false)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @changed_answer_content)).to eq(true)
      end

      it 'should filter out additions and removals with + and -' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        testobj.ignore(type: 'File', title: '/tmp/*', attr: '+')
        testobj.ignore(type: 'File', title: '/tmp/*', attr: '-')
        result = testobj.diff
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @add_answer_content)).to eq(false)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @removed_answer_content)).to eq(false)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @changed_answer_content)).to eq(true)
      end

      it 'should filter out everything with +-~!' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        testobj.ignore(type: 'File', title: '/tmp/*', attr: '+-~!')
        result = testobj.diff
        expect(result.size).to eq(0)
      end

      it 'should not filter based on + being in a string if there are other characters too' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        testobj.ignore(type: 'File', title: '/tmp/*', attr: '+chicken')
        result = testobj.diff
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @add_answer_content)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @removed_answer_content)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @changed_answer_content)).to eq(true)
      end
    end
  end

  context 'ignoring specific changes in attributes' do
    before(:all) do
      @c1 = OctocatalogDiff::Catalog.create(json: OctocatalogDiff::Spec.fixture_read('catalogs/ignore-enhanced-changes-1.json'))
      @c2 = OctocatalogDiff::Catalog.create(json: OctocatalogDiff::Spec.fixture_read('catalogs/ignore-enhanced-changes-2.json'))
      @answer_content = [
        '~',
        "File\f/tmp/awesome\fparameters\fcontent",
        "This is my file.\nMy file is amazing.\nIt is also awesome.",
        "This is my file.\nMy file is cool.\nIt is also awesome."
      ]
      @answer_ensure = [
        '!',
        "File\f/tmp/awesome\fparameters\fensure",
        nil,
        'file'
      ]
      @answer_mode = [
        '~',
        "File\f/tmp/awesome\fparameters\fmode",
        '0755',
        '0644'
      ]
      @answer_notify = [
        '!',
        "File\f/tmp/awesome\fparameters\fnotify",
        'Service[foo]',
        nil
      ]
    end

    context 'without any matching ignores' do
      describe '#ignore' do
        it 'should report all the changes with no ignores' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
          expect(result.size).to eq(4)
        end

        it 'should report all the changes when something irrelevant was ignored' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "parameters\fowner")
          result = testobj.diff
          expect(result.size).to eq(4)
        end
      end
    end

    context 'added / removed attributes' do
      describe '#ignore' do
        it 'should ignore added attributes with +attribute syntax' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '*', attr: "+parameters\fensure")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(false)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should not ignore removed attributes with +attribute syntax' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '*', attr: "+parameters\fnotify")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should not ignore changed attributes with +attribute syntax' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '*', attr: "+parameters\fmode")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should not ignore added attributes with -attribute syntax' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '*', attr: "-parameters\fensure")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should ignore removed attributes with -attribute syntax' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '*', attr: "-parameters\fnotify")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(false)
        end

        it 'should not ignore changed attributes with -attribute syntax' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '*', attr: "-parameters\fmode")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should ignore an added string' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "+parameters\fensure=>file")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(false)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should not ignore a removal when pattern is for added string' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "+parameters\fnotify=>Service[foo]")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should not ignore a change when pattern is for added string' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "+parameters\fmode=>0644")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should ignore a removed string' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "-parameters\fnotify=>Service[foo]")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(false)
        end

        it 'should not ignore an addition when pattern is for removed string' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "-parameters\fensure=>file")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should not ignore a change when pattern is for removed string' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "-parameters\fmode=>0755")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end
      end
    end

    context 'strings' do
      describe '#ignore' do
        it 'should report all the changes when ignore string does not match' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "parameters\fmode=>0555")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should ignore when old string matches' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "parameters\fmode=>0755")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(false)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should ignore when added string matches' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "parameters\fmode=>0644")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(false)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should ignore based on + diff' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "parameters\fmode=+>0644")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(false)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should ignore based on - diff' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "parameters\fmode=->0644")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should not ignore based on non-matching + diff' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "parameters\fmode=+>0755")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should not ignore based on non-matching - diff' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "parameters\fmode=->0755")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(false)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end
      end
    end

    context 'regular expressions' do
      describe '#ignore' do
        it 'should raise error if an invalid regexp is supplied' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "parameters\fmode=~>.*(")
          expect { testobj.diff }.to raise_error(RegexpError, %r{Invalid ignore regexp for File\[/tmp/awesome\] parameters::mode})
        end

        it 'should not ignore a change when regexp does not match' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "parameters\fmode=~>foo.*bar")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should ignore a change when regexp matches old value' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "parameters\fmode=~>.*55")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(false)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should ignore a change when regexp matches new value' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "parameters\fmode=~>.*44")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(false)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should match multi-line' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "parameters\fcontent=~>file is amazing")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(false)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should not match unchanged multi-line' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "parameters\fcontent=~>This is my file")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should use diffy for +' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "parameters\fmode=~>^\\+0644$")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(false)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should use diffy for -' do
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "parameters\fmode=~>^-0644$")
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end
      end
    end

    context 'all lines must match regex' do
      it 'should remove a change when all lines matched a regexp' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "parameters\fcontent=&>file is (amazing|cool)")
        result = testobj.diff
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(false)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
      end

      it 'should not remove a change when not all lines matched a regexp' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        testobj.ignore(type: 'File', title: '/tmp/awesome', attr: "parameters\fcontent=&>file is (amazing|bogus)")
        result = testobj.diff
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
      end
    end

    context 'boolean conditions' do
      describe '#ignore' do
        it 'should ignore a multi-line when all conditions match' do
          attr = [
            "parameters\fcontent=~>file is amazing",
            "parameters\fcontent=~>file is cool"
          ]
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: attr)
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(false)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should ignore a multi-line with diffy markers' do
          attr = [
            "parameters\fcontent=~>^\\-My file is amazing",
            "parameters\fcontent=~>^\\+My file is cool"
          ]
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: attr)
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(false)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should not ignore a multi-line when at one condition does not match (first)' do
          attr = [
            "parameters\fcontent=~>file is bogus",
            "parameters\fcontent=~>file is cool"
          ]
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: attr)
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end

        it 'should not ignore a multi-line when at one condition does not match (last)' do
          attr = [
            "parameters\fcontent=~>file is amazing",
            "parameters\fcontent=~>file is bogus"
          ]
          opts = {}
          testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
          testobj.ignore(type: 'File', title: '/tmp/awesome', attr: attr)
          result = testobj.diff
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_content)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_ensure)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_mode)).to eq(true)
          expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @answer_notify)).to eq(true)
        end
      end
    end
  end

  context 'ignoring type + title + attribute' do
    describe '#ignore' do
      before(:all) do
        @c1 = OctocatalogDiff::Catalog.create(json: OctocatalogDiff::Spec.fixture_read('catalogs/ignore-type-title-attr-1.json'))
        @c2 = OctocatalogDiff::Catalog.create(json: OctocatalogDiff::Spec.fixture_read('catalogs/ignore-type-title-attr-2.json'))
        @tmp_foo_answer_content = [
          '~',
          "File\f/tmp/foo\fparameters\fcontent",
          'this is a file of foo',
          'this is a file of foo with updated content'
        ]
        @tmp_bar_answer_content = [
          '~',
          "File\f/tmp/bar\fparameters\fcontent",
          'this is a file of bar',
          'this is a file of bar with updated content'
        ]
        @tmp_bar_answer_owner = [
          '~',
          "File\f/tmp/bar\fparameters\fowner",
          'root',
          'baruser'
        ]
        @tmp_bar_answer_group = [
          '~',
          "File\f/tmp/bar\fparameters\fgroup",
          'root',
          'baruser'
        ]
      end

      it 'should not filter out a change when attribute does not match' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        testobj.ignore(type: 'File', title: '/tmp/foo', attr: "parameters\fmode")
        result = testobj.diff
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_foo_answer_content)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_bar_answer_content)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_bar_answer_owner)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_bar_answer_group)).to eq(true)
      end

      it 'should not filter out a change when title does not match' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        testobj.ignore(type: 'File', title: '/tmp/foo', attr: "parameters\fmode")
        result = testobj.diff
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_foo_answer_content)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_bar_answer_content)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_bar_answer_owner)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_bar_answer_group)).to eq(true)
      end

      it 'should filter out a change when attribute matches' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        testobj.ignore(type: 'File', title: '/tmp/foo', attr: "parameters\fcontent")
        result = testobj.diff
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_foo_answer_content)).to eq(false)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_bar_answer_content)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_bar_answer_owner)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_bar_answer_group)).to eq(true)
      end

      it 'should suppress part of a change when one attribute matches' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        testobj.ignore(type: 'File', title: '/tmp/bar', attr: "parameters\fcontent")
        result = testobj.diff
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_foo_answer_content)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_bar_answer_content)).to eq(false)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_bar_answer_owner)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_bar_answer_group)).to eq(true)
      end

      it 'should suppress part of a change when one attribute matches with wildcard' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        testobj.ignore(type: 'File', title: '/tmp/*', attr: "parameters\fcontent")
        result = testobj.diff
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_foo_answer_content)).to eq(false)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_bar_answer_content)).to eq(false)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_bar_answer_owner)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_bar_answer_group)).to eq(true)
      end

      it 'should handle multiple ignore attributes' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        testobj.ignore(type: 'File', title: '/tmp/foo', attr: "parameters\fcontent")
        testobj.ignore(type: 'File', title: '/tmp/bar', attr: "parameters\fgroup")
        result = testobj.diff
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_foo_answer_content)).to eq(false)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_bar_answer_content)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_bar_answer_owner)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @tmp_bar_answer_group)).to eq(false)
      end
    end
  end

  context 'ignoring changes in sets' do
    describe '#ignore' do
      before(:all) do
        @c1 = OctocatalogDiff::Catalog.create(json: OctocatalogDiff::Spec.fixture_read('catalogs/ignore-parameter-set-1.json'))
        @c2 = OctocatalogDiff::Catalog.create(json: OctocatalogDiff::Spec.fixture_read('catalogs/ignore-parameter-set-2.json'))
        @set1 = [
          '!',
          "Myres\fres1\fparameters\fset1",
          %w(one two three),
          %w(three two one)
        ]
        @set2 = [
          '!',
          "Myres\fres1\fparameters\fset2",
          %w(a b),
          %w(a b c)
        ]
        @set3 = [
          '!',
          "Myres\fres1\fparameters\fset3",
          nil,
          [1, 2, 3]
        ]
      end

      it 'should not filter out a change when attribute does not match' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        testobj.ignore(type: 'Myres', title: 'res1', attr: "parameters\fmode")
        result = testobj.diff
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @set1)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @set2)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @set3)).to eq(true)
      end

      it 'should filter out a change when two arrays have set equality' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        testobj.ignore(type: 'Myres', title: 'res1', attr: "parameters\fset1=s>=")
        result = testobj.diff
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @set1)).to eq(false)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @set2)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @set3)).to eq(true)
      end

      it 'should not filter out a change when two arrays are not equivalent sets' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        testobj.ignore(type: 'Myres', title: 'res1', attr: "parameters\fset2=s>=")
        result = testobj.diff
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @set1)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @set2)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @set3)).to eq(true)
      end

      it 'should not filter out a change when one array is not specified' do
        opts = {}
        testobj = OctocatalogDiff::CatalogDiff::Differ.new(opts, @c1, @c2)
        testobj.ignore(type: 'Myres', title: 'res1', attr: "parameters\fset3=s>=")
        result = testobj.diff
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @set1)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @set2)).to eq(true)
        expect(OctocatalogDiff::Spec.array_contains_partial_array?(result, @set3)).to eq(true)
      end
    end
  end

  describe '#ignore_match?' do
    let(:resource) { { type: 'Apple', title: 'delicious', attr: "parameters\fcolor" } }
    let(:testobj) { described_class.allocate }

    context 'type regex' do
      it 'should filter matching resource' do
        rule = { type: Regexp.new('A.+e\z'), title: '*', attr: '*' }
        logger, logger_str = OctocatalogDiff::Spec.setup_logger
        testobj.instance_variable_set('@logger', logger)
        expect(testobj.send(:"ignore_match?", rule, '+', resource, 'old_value', 'new_value')).to eq(true)
        expect(logger_str.string).to match(%r[Ignoring .+ matches {:type=>/A.+e\\z/, :title=>"\*", :attr=>"\*"}])
      end

      it 'should not filter non-matching resource' do
        rule = { type: Regexp.new('A.+b\z'), title: '*', attr: '*' }
        logger, logger_str = OctocatalogDiff::Spec.setup_logger
        testobj.instance_variable_set('@logger', logger)
        expect(testobj.send(:"ignore_match?", rule, '+', resource, 'old_value', 'new_value')).to eq(false)
        expect(logger_str.string).not_to match(%r[Ignoring .+ matches {:type=>/A.+b\\z/, :title=>"\*", :attr=>"\*"}])
      end
    end

    context 'type string' do
      it 'should filter matching resource' do
        rule = { type: 'Apple', title: '*', attr: '*' }
        logger, logger_str = OctocatalogDiff::Spec.setup_logger
        testobj.instance_variable_set('@logger', logger)
        expect(testobj.send(:"ignore_match?", rule, '+', resource, 'old_value', 'new_value')).to eq(true)
        expect(logger_str.string).to match(/Ignoring .+ matches {:type=>"Apple", :title=>"\*", :attr=>"\*"}/)
      end

      it 'should not filter non-matching resource' do
        rule = { type: 'Banana', title: '*', attr: '*' }
        logger, logger_str = OctocatalogDiff::Spec.setup_logger
        testobj.instance_variable_set('@logger', logger)
        expect(testobj.send(:"ignore_match?", rule, '+', resource, 'old_value', 'new_value')).to eq(false)
        expect(logger_str.string).not_to match(/Ignoring .+ matches {:type=>"Banana", :title=>"\*", :attr=>"\*"}/)
      end
    end

    context 'title regex' do
      it 'should filter matching resource' do
        rule = { type: '*', title: Regexp.new('del.+ous'), attr: '*' }
        logger, logger_str = OctocatalogDiff::Spec.setup_logger
        testobj.instance_variable_set('@logger', logger)
        expect(testobj.send(:"ignore_match?", rule, '+', resource, 'old_value', 'new_value')).to eq(true)
        expect(logger_str.string).to match(%r[Ignoring .+ matches {:type=>"\*", :title=>/del\.\+ous/, :attr=>"\*"}])
      end

      it 'should not filter non-matching resource' do
        rule = { type: '*', title: Regexp.new('dell.+ous'), attr: '*' }
        logger, logger_str = OctocatalogDiff::Spec.setup_logger
        testobj.instance_variable_set('@logger', logger)
        expect(testobj.send(:"ignore_match?", rule, '+', resource, 'old_value', 'new_value')).to eq(false)
        expect(logger_str.string).not_to match(%r[Ignoring .+ matches {:type=>"\*", :title=>/dell\.\+ous/, :attr=>"\*"}])
      end
    end

    context 'title string' do
      it 'should filter matching resource' do
        rule = { type: '*', title: 'delicious', attr: '*' }
        logger, logger_str = OctocatalogDiff::Spec.setup_logger
        testobj.instance_variable_set('@logger', logger)
        expect(testobj.send(:"ignore_match?", rule, '+', resource, 'old_value', 'new_value')).to eq(true)
        expect(logger_str.string).to match(/Ignoring .+ matches {:type=>"\*", :title=>"delicious", :attr=>"\*"}/)
      end

      it 'should not filter non-matching resource' do
        rule = { type: '*', title: 'dell', attr: '*' }
        logger, logger_str = OctocatalogDiff::Spec.setup_logger
        testobj.instance_variable_set('@logger', logger)
        expect(testobj.send(:"ignore_match?", rule, '+', resource, 'old_value', 'new_value')).to eq(false)
        expect(logger_str.string).not_to match(/Ignoring .+ matches {:type=>"\*", :title=>"dell", :attr=>"\*"}/)
      end
    end

    context 'attrs regexp' do
      it 'should filter on regular expression match' do
        rule = { type: 'Apple', title: 'delicious', attr: Regexp.new("\\Aparameters\f(color|taste)\\z") }
        logger, logger_str = OctocatalogDiff::Spec.setup_logger
        testobj.instance_variable_set('@logger', logger)
        expect(testobj.send(:"ignore_match?", rule, '+', resource, 'old_value', 'new_value')).to eq(true)
        expect(logger_str.string).to match(/Ignoring .+ matches {:type=>"Apple", :title=>"delicious", :attr=>/)
      end

      it 'should not filter on regular expression non-match' do
        rule = { type: 'Apple', title: 'delicious', attr: Regexp.new("\\Aparameters\f(odor|has_worms)\\z") }
        logger, logger_str = OctocatalogDiff::Spec.setup_logger
        testobj.instance_variable_set('@logger', logger)
        expect(testobj.send(:"ignore_match?", rule, '+', resource, 'old_value', 'new_value')).to eq(false)
        expect(logger_str.string).not_to match(/Ignoring .+ matches/)
      end
    end
  end

  describe '#ignore_tags' do
    let(:catalog_1) { OctocatalogDiff::Catalog.create(json: OctocatalogDiff::Spec.fixture_read('catalogs/ignore-tags-old.json')) }
    let(:catalog_2) { OctocatalogDiff::Catalog.create(json: OctocatalogDiff::Spec.fixture_read('catalogs/ignore-tags-new.json')) }
    let(:opts) { { ignore_tags: ['ignored_catalog_diff'] } }
    let(:answer) { JSON.parse(OctocatalogDiff::Spec.fixture_read('diffs/ignore-tags-partial.json')) }

    it 'should remove tagged-for-ignore resources' do
      logger, logger_str = OctocatalogDiff::Spec.setup_logger
      subject = described_class.new(opts.merge(logger: logger), catalog_1, catalog_2)
      subject.ignore_tags

      ignore_answer = [
        { type: 'Mymodule::Resource1', title: 'one', attr: '*' },
        { type: 'Mymodule::Resource1', title: 'two', attr: '*' },
        { type: 'Mymodule::Resource1', title: 'three', attr: '*' },
        { type: 'Mymodule::Resource1', title: 'four', attr: '*' },
        { type: 'Mymodule::Resource2', title: 'five', attr: '*' },
        { type: 'File', title: '/tmp/ignored/one', attr: '*' },
        { type: 'File', title: '/tmp/new-file/ignored/one', attr: '*' },
        { type: 'File', title: '/tmp/ignored/two', attr: '*' },
        { type: 'File', title: '/tmp/new-file/ignored/two', attr: '*' },
        { type: 'File', title: '/tmp/ignored/three', attr: '*' },
        { type: 'File', title: '/tmp/new-file/ignored/three', attr: '*' },
        { type: 'File', title: '/tmp/ignored/four', attr: '*' },
        { type: 'File', title: '/tmp/new-file/ignored/four', attr: '*' },
        { type: 'File', title: '/tmp/resource2/five', attr: '*' },
        { type: 'File', title: '/tmp/ignored/five', attr: '*' },
        { type: 'File', title: '/tmp/new-file/ignored/five', attr: '*' },
        { type: 'File', title: '/tmp/old-file/ignored/one', attr: '*' },
        { type: 'File', title: '/tmp/old-file/ignored/two', attr: '*' },
        { type: 'File', title: '/tmp/old-file/ignored/three', attr: '*' },
        { type: 'File', title: '/tmp/old-file/ignored/four', attr: '*' },
        { type: 'File', title: '/tmp/old-file/ignored/five', attr: '*' }
      ]

      ignores = subject.instance_variable_get('@ignore')
      expect(ignores.size).to eq(ignore_answer.size)
      ignore_answer.each { |answer| expect(ignores).to include(answer) }

      expect(logger_str.string).to match(/Ignoring type='Mymodule::Resource1', title='one' based on tag in to-catalog/)
      r = %r{Ignoring type='File', title='/tmp/old-file/ignored/one' based on tag in from-catalog}
      expect(logger_str.string).to match(r)
    end
  end

  describe '#hashdiff_nested_changes' do
    it 'should return array with proper results' do
      hashdiff_add_remove = [
        "Class\fOpenssl::Package\fparameters\fcommon-array"
      ]

      empty_puppet_catalog_json = File.read(OctocatalogDiff::Spec.fixture_path('catalogs/catalog-empty.json'))
      empty_puppet_catalog = OctocatalogDiff::Catalog.create(json: empty_puppet_catalog_json)
      obj = OctocatalogDiff::CatalogDiff::Differ.new({}, empty_puppet_catalog, empty_puppet_catalog)

      cat1 = [
        {
          'type' => 'Class',
          'title' => 'Openssl::Package',
          'parameters' => { 'common-array' => [1, 2, 3] },
          'file' => '/var/tmp/foo',
          'line' => 5
        }
      ]

      cat2 = [
        {
          'type' => 'Class',
          'title' => 'Openssl::Package',
          'parameters' => { 'common-array' => [1, 5, 25] },
          'file' => '/var/tmp/foo',
          'line' => 5
        }
      ]

      remaining1 = obj.send(:resources_as_hashes_with_serialized_keys, cat1)
      remaining2 = obj.send(:resources_as_hashes_with_serialized_keys, cat2)

      result = obj.send(:hashdiff_nested_changes, hashdiff_add_remove, remaining1, remaining2)
      expect(result).to be_a_kind_of(Array)
      expect(result.size).to eq(1)

      fileref = { 'file' => '/var/tmp/foo', 'line' => 5 }
      expect(result[0]).to eq(['!', "Class\fOpenssl::Package\fparameters\fcommon-array", [1, 2, 3], [1, 5, 25], fileref, fileref])
    end
  end

  describe '#regexp_operator_match?' do
    let(:subject) { described_class.allocate }

    context 'for a multi-line diff' do
      context 'for operator =~>' do
        let(:operator) { '=~>' }
        let(:regex) { Regexp.new('\\A.(kittens|cats)\\z') }

        it 'should return true when at least one line matches' do
          old_val = "kittens\nkittens\ncats\n"
          new_val = "puppies\ndogs\n"
          expect(subject.send(:regexp_operator_match?, operator, regex, old_val, new_val)).to eq(true)
        end

        it 'should return false when neither line matches' do
          old_val = "puppies\ndogs\ndonkeys\n"
          new_val = "puppies\ndogs\n"
          expect(subject.send(:regexp_operator_match?, operator, regex, old_val, new_val)).to eq(false)
        end
      end

      context 'for operator =&>' do
        let(:operator) { '=&>' }
        let(:regex) { Regexp.new('\\A(-|\\+)(kittens )*(kittens|cats)\\z') }

        it 'should return true when all lines match' do
          old_val = "kittens\nkittens\ncats\n"
          new_val = "kittens\nkittens\n"
          expect(subject.send(:regexp_operator_match?, operator, regex, old_val, new_val)).to eq(true)
        end

        it 'should return false when the regex does not match line' do
          old_val = "kittens\nkittens\ncats\n"
          new_val = "kittens\nkittens\ndogs\n"
          expect(subject.send(:regexp_operator_match?, operator, regex, old_val, new_val)).to eq(false)
        end

        it 'should return true if both old and new do not end in a newline' do
          old_val = "kittens\nkittens\ncats"
          new_val = "kittens\nkittens\nkittens"
          expect(subject.send(:regexp_operator_match?, operator, regex, old_val, new_val)).to eq(true)
        end

        it 'should return false if one ends in a newline and the other does not' do
          old_val = "kittens\nkittens\ncats\n"
          new_val = "kittens\nkittens\nkittens"
          expect(subject.send(:regexp_operator_match?, operator, regex, old_val, new_val)).to eq(false)
        end
      end
    end

    context 'for a single-line diff' do
      context 'for operator =~>' do
        let(:operator) { '=~>' }
        let(:regex) { Regexp.new('\\A(-|\\+)(kittens )+(kittens|cats)\\z') }

        it 'should return true when at least one line matches' do
          old_val = 'kittens kittens kittens'
          new_val = 'kittens cats'
          expect(subject.send(:regexp_operator_match?, operator, regex, old_val, new_val)).to eq(true)
        end

        it 'should return false when neither line matches' do
          old_val = 'kittens dogs cats kittens kittens'
          new_val = 'kittens cats dogs'
          expect(subject.send(:regexp_operator_match?, operator, regex, old_val, new_val)).to eq(false)
        end
      end

      context 'for operator =&>' do
        let(:operator) { '=&>' }
        let(:regex) { Regexp.new('\\A(-|\\+)(kittens )+(kittens|cats)\\z') }

        it 'should return true when both lines match' do
          old_val = 'kittens kittens kittens'
          new_val = 'kittens cats'
          expect(subject.send(:regexp_operator_match?, operator, regex, old_val, new_val)).to eq(true)
        end

        it 'should return false when the regex does not match line' do
          old_val = 'kittens kittens dogs kittens'
          new_val = 'kittens cats'
          expect(subject.send(:regexp_operator_match?, operator, regex, old_val, new_val)).to eq(false)
        end
      end
    end

    context 'for a multi-line versus a single-line diff' do
      context 'for operator =~>' do
        let(:operator) { '=~>' }
        let(:regex) { Regexp.new('\\A.(kittens|cats)\\z') }

        it 'should return true when at least one line matches' do
          old_val = "kittens\nkittens\ncats\n"
          new_val = 'puppies'
          expect(subject.send(:regexp_operator_match?, operator, regex, old_val, new_val)).to eq(true)
        end

        it 'should return false when neither line matches' do
          old_val = "puppies\ndogs\ndonkeys\n"
          new_val = 'puppies'
          expect(subject.send(:regexp_operator_match?, operator, regex, old_val, new_val)).to eq(false)
        end
      end

      context 'for operator =&>' do
        let(:operator) { '=&>' }
        let(:regex) { Regexp.new('\\A(-|\\+)(kittens )*(kittens|cats)\\z') }

        it 'should return true when all lines match and both old and new do not end in newline' do
          old_val = "kittens\nkittens\ncats"
          new_val = 'kittens'
          expect(subject.send(:regexp_operator_match?, operator, regex, old_val, new_val)).to eq(true)
        end

        it 'should return false when all lines match but ending in newlines differs' do
          old_val = "kittens\nkittens\ncats\n"
          new_val = 'kittens'
          expect(subject.send(:regexp_operator_match?, operator, regex, old_val, new_val)).to eq(false)
        end

        it 'should return false when the regex does not match line' do
          old_val = "kittens\nkittens\ncats"
          new_val = 'dogs'
          expect(subject.send(:regexp_operator_match?, operator, regex, old_val, new_val)).to eq(false)
        end
      end
    end
  end
end
