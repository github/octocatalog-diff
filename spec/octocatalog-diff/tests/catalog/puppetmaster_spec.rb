# frozen_string_literal: true

require 'json'

require_relative '../spec_helper'

require OctocatalogDiff::Spec.require_path('/catalog')
require OctocatalogDiff::Spec.require_path('/catalog/puppetmaster')

describe OctocatalogDiff::Catalog::PuppetMaster do
  let(:valid_options) do
    {
      node: 'foo',
      branch: 'foobranch',
      puppet_master: 'fake-puppetmaster.non-existent-domain.com',
      fact_file: OctocatalogDiff::Spec.fixture_path('facts/facts_esc.yaml')
    }
  end

  describe '#new' do
    it 'should raise ArgumentError when options hash is not passed' do
      expect { OctocatalogDiff::Catalog::PuppetMaster.new }.to raise_error(ArgumentError)
      expect { OctocatalogDiff::Catalog::PuppetMaster.new(true) }.to raise_error(ArgumentError)
    end

    it 'should raise ArgumentError when options hash does not contain a valid node' do
      opts = valid_options.reject { |x| x == :node }
      expect { OctocatalogDiff::Catalog::PuppetMaster.new(opts) }.to raise_error(ArgumentError)
      expect { OctocatalogDiff::Catalog::PuppetMaster.new(opts.merge(node: {})) }.to raise_error(ArgumentError)
    end

    it 'should raise ArgumentError when options hash does not contain a valid branch' do
      opts = valid_options.reject { |x| x == :branch }
      expect { OctocatalogDiff::Catalog::PuppetMaster.new(opts) }.to raise_error(ArgumentError)
      expect { OctocatalogDiff::Catalog::PuppetMaster.new(opts.merge(branch: {})) }.to raise_error(ArgumentError)
    end

    it 'should raise ArgumentError when options hash does not contain a valid puppet master' do
      opts = valid_options.reject { |x| x == :puppet_master }
      expect { OctocatalogDiff::Catalog::PuppetMaster.new(opts) }.to raise_error(ArgumentError)
      expect { OctocatalogDiff::Catalog::PuppetMaster.new(opts.merge(puppet_master: {})) }.to raise_error(ArgumentError)
    end

    it 'should add default port number to a puppet master with no port' do
      obj = OctocatalogDiff::Catalog::PuppetMaster.new(valid_options)
      expect(obj.options[:puppet_master]).to eq('fake-puppetmaster.non-existent-domain.com:8140')
    end

    it 'should not add default port number to a puppet master with a port' do
      obj = OctocatalogDiff::Catalog::PuppetMaster.new(valid_options.merge(puppet_master: 'localhost:8139'))
      expect(obj.options[:puppet_master]).to eq('localhost:8139')
    end
  end

  describe '#build' do
    context 'with bad parameters' do
      it 'should error if the PuppetDB API version is outside the permissible range' do
        obj = OctocatalogDiff::Catalog::PuppetMaster.new(valid_options.merge(puppet_master_api_version: 1000))
        expect { obj.build }.to raise_error(ArgumentError, /Unsupported or invalid API version/)
      end
    end

    context 'with valid parameters' do
      before(:each) do
        @url = nil
        @opts = nil
        @post_data = nil
        @context = nil
        allow(OctocatalogDiff::Util::HTTParty).to receive(:post) do |url, opts, post_data, context|
          @url = url
          @opts = opts
          @post_data = post_data
          @context = context
          {
            code: 200,
            parsed: JSON.parse(File.read(OctocatalogDiff::Spec.fixture_path(fixture_catalog)))
          }
        end
      end

      let(:api_url) do
        {
          2 => 'https://fake-puppetmaster.non-existent-domain.com:8140/foobranch/catalog/foo',
          3 => 'https://fake-puppetmaster.non-existent-domain.com:8140/puppet/v3/catalog/foo',
          4 => 'https://fake-puppetmaster.non-existent-domain.com:8140/puppet/v4/catalog'
        }
      end

      let(:api_sets_environment) { { 2 => false, 3 => true } }
      let(:fixture_catalog) { 'catalogs/tiny-catalog.json' }

      [2, 3].each do |api_version|
        context "api v#{api_version}" do
          before(:each) do
            opts = { puppet_master_api_version: api_version }
            @obj = OctocatalogDiff::Catalog::PuppetMaster.new(valid_options.merge(opts))
            @logger, @logger_str = OctocatalogDiff::Spec.setup_logger
            @obj.build(@logger)
          end

          it 'should post to the correct URL' do
            expect(@url).to eq(api_url[api_version])
          end

          it 'should set the Accept header' do
            expect(@opts[:headers]['Accept']).to eq('text/pson')
          end

          it 'should post the correct facts to HTTParty' do
            answer = JSON.parse(File.read(OctocatalogDiff::Spec.fixture_path('facts/facts_esc.json')))
            answer.delete('_timestamp')
            # An extra 'unescape' is here because the facts are double escaped.
            # See https://docs.puppet.com/puppet/latest/http_api/http_catalog.html#parameters
            # and https://github.com/puppetlabs/puppet/pull/1818
            data = CGI.unescape(@post_data['facts'], 'UTF-8')
            result = JSON.parse(data)['values']
            expect(result).to eq(answer)
          end

          it 'should set the environment in the parameters correctly for the API' do
            expect(@post_data.key?('environment')).to eq(api_sets_environment[api_version])
          end

          it 'should parse the response and set instance variables correctly' do
            expect(@obj.catalog).to be_a_kind_of(Hash)
            expect(@obj.catalog_json).to be_a_kind_of(String)
            expect(@obj.error_message).to eq(nil)
          end

          it 'should log correctly' do
            logs = @logger_str.string
            expect(logs).to match(/Start retrieving facts for foo from OctocatalogDiff::Catalog::PuppetMaster/)
            expect(logs).to match(%r{Retrieving facts from.*fixtures/facts/facts_esc.yaml})
            expect(logs).to match(%r{Retrieving facts from.*fixtures/facts/facts_esc.yaml})

            answer = Regexp.new("Retrieve catalog from #{api_url[api_version]} environment foobranch")
            expect(logs).to match(answer)

            answer2 = Regexp.new("Response from #{api_url[api_version]} environment foobranch was 200")
            expect(logs).to match(answer2)
          end
        end
      end

      context 'api v4' do
        let(:fixture_catalog) { 'catalogs/tiny-catalog-v4-api.json' }
        let(:extra_opts) { {} }

        before(:each) do
          opts = { puppet_master_api_version: 4 }
          @obj = OctocatalogDiff::Catalog::PuppetMaster.new(valid_options.merge(opts).merge(extra_opts))
          @logger, @logger_str = OctocatalogDiff::Spec.setup_logger
          @obj.build(@logger)
          @parsed_data = JSON.parse(@post_data)
        end

        it 'should post to the correct URL' do
          expect(@url).to eq(api_url[4])
        end

        it 'should set the Content-Type header correctly' do
          expect(@opts[:headers]['Content-Type']).to eq('application/json')
        end

        it 'should not set the X-Authentication header when no token is provided' do
          expect(@opts[:headers].key?('X-Authentication')).to eq false
        end

        it 'should post the correct facts to HTTParty' do
          answer = JSON.parse(File.read(OctocatalogDiff::Spec.fixture_path('facts/facts_esc.json')))
          answer.delete('_timestamp')
          result = @parsed_data['facts']['values']
          expect(result).to eq(answer)
        end

        it 'should set the environment in the parameters correctly for the API' do
          expect(@parsed_data['environment']).to eq('foobranch')
        end

        it 'should default to false for persistence' do
          expect(@parsed_data['persistence']['facts']).to eq false
          expect(@parsed_data['persistence']['catalog']).to eq false
        end

        it 'should parse the response and set instance variables correctly' do
          expect(@obj.catalog).to be_a_kind_of(Hash)
          expect(@obj.catalog_json).to be_a_kind_of(String)
          expect(@obj.error_message).to eq(nil)
        end

        it 'should log correctly' do
          logs = @logger_str.string
          expect(logs).to match(/Start retrieving facts for foo from OctocatalogDiff::Catalog::PuppetMaster/)
          expect(logs).to match(%r{Retrieving facts from.*fixtures/facts/facts_esc.yaml})
          expect(logs).to match(%r{Retrieving facts from.*fixtures/facts/facts_esc.yaml})

          answer = Regexp.new("Retrieve catalog from #{api_url[4]} environment foobranch")
          expect(logs).to match(answer)

          answer2 = Regexp.new("Response from #{api_url[4]} environment foobranch was 200")
          expect(logs).to match(answer2)
        end

        context 'when a RBAC token is passed' do
          let(:extra_opts) { { puppet_master_token: 'mytoken' } }

          it 'should set the token in the headers' do
            expect(@opts[:headers]['X-Authentication']).to eq 'mytoken'
          end
        end

        context 'when facts persistence is requested' do
          let(:extra_opts) { { puppet_master_update_facts: true } }

          it 'should set the request in the parameters' do
            expect(@parsed_data['persistence']['facts']).to eq true
          end
        end

        context 'when catalog persistence is requested' do
          let(:extra_opts) { { puppet_master_update_catalog: true } }

          it 'should set the request in the parameters' do
            expect(@parsed_data['persistence']['catalog']).to eq true
          end
        end
      end

      context 'response is not 200' do
        before(:each) do
          allow(OctocatalogDiff::Util::HTTParty).to receive(:post) do |_url, _opts, _post_data, _context|
            {
              code: 400,
              body: 'Catalog compilation failed because something is wrong'
            }
          end
          opts = { puppet_master_api_version: 3 }
          @obj = OctocatalogDiff::Catalog::PuppetMaster.new(valid_options.merge(opts))
          @obj.build
        end

        it 'should set the error message' do
          expect(@obj.error_message).to match(/Failed to retrieve catalog from.*: 400 Catalog compilation failed/)
        end

        it 'should set the catalog to nil' do
          expect(@obj.catalog).to eq(nil)
        end

        it 'should set the catalog json to nil' do
          expect(@obj.catalog).to eq(nil)
        end
      end
    end
  end
end
