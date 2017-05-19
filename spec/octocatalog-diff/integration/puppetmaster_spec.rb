# frozen_string_literal: true

require_relative 'integration_helper'

require 'json'

module OctocatalogDiff
  class PuppetMasterIntegration
    class Server
      def initialize(options = {})
        server_opts = options.dup
        server_opts[:rsa_key] ||= File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/server.key'))
        server_opts[:cert] ||= File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/server.crt'))
        @test_server = nil
        3.times do
          @test_server = SSLTestServer.new(server_opts)
          @test_server.start
          break if @test_server.port > 0
        end
        raise OctocatalogDiff::Spec::FixtureError, 'Unable to instantiate SSLTestServer' unless @test_server.port > 0
      end

      def stop
        @test_server.stop
      end

      def port
        @test_server.port
      end
    end

    class Util
      def self.respond(code, message, content_type = nil, body = '')
        response = "HTTP/1.1 #{code} #{message}\n"
        response += "Connection: close\n"
        response += "Content-Type: #{content_type}; charset=UTF-8\n" if content_type
        response += "Content-Length: #{body.length}\n"
        response += "\n"
        response += body
        response
      end

      def self.parse_body(body)
        require 'cgi'
        pairs = body.split('&').map { |x| CGI.unescape(x).split('=', 2) }
        pairs.inject({}) { |a, e| a.merge!(e[0] => e[1]) }
      end

      def self.facts_match(body)
        facts = JSON.parse(CGI.unescape(parse_body(body)['facts']))
        facts.delete('_timestamp')
        desired_facts = {
          'name' => 'rspec-node.xyz.github.net',
          'values' => JSON.parse(File.read(OctocatalogDiff::Spec.fixture_path('facts/facts.json')))
        }
        desired_facts['values'].delete('_timestamp')

        return nil if facts == desired_facts
        respond(499, 'Wrong facts', nil, '{"error":"Wrong facts"}')
      end
    end

    class CatalogWithFactsV2 < OctocatalogDiff::PuppetMasterIntegration::Util
      def self.response(method, uri, _headers, body)
        if method != :post
          return respond(400, 'Bad Request', nil, '{"error":"Only POST is supported here"}')
        end
        if uri != '/production/catalog/my.rspec.node'
          return respond(404, 'Not Found', nil, '{"error":"Unexpected URL received"}')
        end
        catalog = File.read(OctocatalogDiff::Spec.fixture_path('catalogs/catalog-2.json'))
                      .gsub(/\r\n/n, "\n").gsub(/\n/n, "\r\n")
        facts_match(body) || respond(200, 'OK', 'application/pson', catalog)
      end
    end

    class CatalogWithFactsV3 < OctocatalogDiff::PuppetMasterIntegration::Util
      def self.response(method, uri, _headers, body)
        if method != :post
          return respond(400, 'Bad Request', nil, '{"error":"Only POST is supported here"}')
        end
        if uri != '/puppet/v3/catalog/my.rspec.node'
          return respond(404, 'Not Found', nil, '{"error":"Unexpected URL received"}')
        end
        catalog = File.read(OctocatalogDiff::Spec.fixture_path('catalogs/catalog-2-v4.json'))
                      .gsub(/\r\n/n, "\n").gsub(/\n/n, "\r\n")
        facts_match(body) || respond(200, 'OK', 'application/pson', catalog)
      end
    end
  end
end

context 'APIv2' do
  describe 'obtaining a catalog from a puppetmaster' do
    before(:all) do
      opts = {
        ca_file: OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'),
        client_verify: true,
        handler: OctocatalogDiff::PuppetMasterIntegration::CatalogWithFactsV2
      }
      @server = OctocatalogDiff::PuppetMasterIntegration::Server.new(opts)
      @puppetmaster = "localhost:#{@server.port}"
    end

    after(:all) do
      @server.stop
    end

    it 'should succeed when facts are sent properly' do
      opts = {
        argv: [
          '--to-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/catalog-1.json'),
          '--from-puppet-master', @puppetmaster,
          '--puppet-master-ssl-client-key', OctocatalogDiff::Spec.fixture_path('ssl/generated/client.key'),
          '--puppet-master-ssl-client-cert', OctocatalogDiff::Spec.fixture_path('ssl/generated/client.crt'),
          '--puppet-master-api-version', '2',
          '-f', 'production'
        ],
        spec_fact_file: 'facts.yaml'
      }
      result = OctocatalogDiff::Integration.integration(opts)
      expect(result[:exitcode]).to eq(2), OctocatalogDiff::Integration.format_exception(result)
      expect(result[:logs]).to match(/Initialized OctocatalogDiff::Catalog::PuppetMaster for from-catalog/)
      expect(result[:logs]).to match(/--compare-file-text; not supported by OctocatalogDiff::Catalog::PuppetMaster/)
      expect(result[:logs]).to match(/Diffs computed for my.rspec.node/)
      expect(result[:diffs]).to be_a_kind_of(Array)
      expect(result[:diffs].size).to eq(14)
    end
  end
end

context 'APIv3' do
  describe 'obtaining a catalog from a puppetmaster' do
    before(:all) do
      opts = {
        ca_file: OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'),
        client_verify: true,
        handler: OctocatalogDiff::PuppetMasterIntegration::CatalogWithFactsV3
      }
      @server = OctocatalogDiff::PuppetMasterIntegration::Server.new(opts)
      @puppetmaster = "localhost:#{@server.port}"
    end

    after(:all) do
      @server.stop
    end

    # This is a test to ensure that the SSL server is actually requiring client authentication.
    # This catalog compilation should fail (quickly) since no client auth data is provided.
    it 'should fail with no SSL certificate details' do
      opts = {
        argv: [
          '--from-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/default-catalog-v4.json'),
          '--to-puppet-master', @puppetmaster
        ],
        spec_fact_file: 'facts.yaml'
      }
      result = OctocatalogDiff::Integration.integration(opts)
      expect(result[:exitcode]).to eq(-1)
      expect(result[:exception].class.to_s).to eq('OpenSSL::SSL::SSLError')
    end

    it 'should fail when the node is not found in PuppetDB' do
      opts = {
        argv: [
          '--from-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/default-catalog-v4.json'),
          '--to-puppet-master', @puppetmaster,
          '--puppet-master-ssl-client-key', OctocatalogDiff::Spec.fixture_path('ssl/generated/client.key'),
          '--puppet-master-ssl-client-cert', OctocatalogDiff::Spec.fixture_path('ssl/generated/client.crt'),
          '-n', 'foobaz.local'
        ],
        spec_fact_file: 'facts.yaml'
      }
      result = OctocatalogDiff::Integration.integration(opts)
      expect(result[:exitcode]).to eq(-1)
      expect(result[:exception].class.to_s).to eq('OctocatalogDiff::Errors::CatalogError')
      expect(result[:exception].message).to match(/foobaz.local: 404/)
    end

    it 'should succeed when facts are sent properly' do
      opts = {
        argv: [
          '--to-catalog', OctocatalogDiff::Spec.fixture_path('catalogs/catalog-1-v4.json'),
          '--from-puppet-master', @puppetmaster,
          '--puppet-master-ssl-client-key', OctocatalogDiff::Spec.fixture_path('ssl/generated/client.key'),
          '--puppet-master-ssl-client-cert', OctocatalogDiff::Spec.fixture_path('ssl/generated/client.crt'),
          '-f', 'production'
        ],
        spec_fact_file: 'facts.yaml'
      }
      result = OctocatalogDiff::Integration.integration(opts)
      expect(result[:exitcode]).to eq(2), OctocatalogDiff::Integration.format_exception(result)
      expect(result[:logs]).to match(/Initialized OctocatalogDiff::Catalog::PuppetMaster for from-catalog/)
      expect(result[:logs]).to match(/--compare-file-text; not supported by OctocatalogDiff::Catalog::PuppetMaster/)
      expect(result[:logs]).to match(/Diffs computed for my.rspec.node/)
      expect(result[:diffs]).to be_a_kind_of(Array)
      expect(result[:diffs].size).to eq(14)
    end
  end
end
