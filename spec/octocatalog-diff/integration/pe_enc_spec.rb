# frozen_string_literal: true

require_relative 'integration_helper'

require 'fileutils'
require 'json'
require 'yaml'

module OctocatalogDiff
  class PuppetEnterpriseENCIntegration
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

    class Handler
      def self.response(method, uri, _headers, _body)
        if method != :post
          return respond(400, 'Bad Request', nil, '{"error":"Only POST is supported here"}')
        end
        if uri != '/classifier-api/v1/classified/nodes/rspec-node.xyz.github.net'
          return respond(404, 'Not Found', nil, '{"error":"Unexpected URL received"}')
        end
        content = OctocatalogDiff::Spec.fixture_read('enc/puppet-enterprise-enc.yaml').gsub(/\r\n/n, "\n").gsub(/\n/n, "\r\n")
        response_content = YAML.load(content).to_json
        respond(200, 'OK', 'application/json', response_content)
      end

      def self.respond(code, message, content_type = nil, body = '')
        response = "HTTP/1.1 #{code} #{message}\n"
        response += "Connection: close\n"
        response += "Content-Type: #{content_type}; charset=UTF-8\n" if content_type
        response += "Content-Length: #{body.length}\n"
        response += "\n"
        response += body
        response
      end
    end
  end
end

describe 'with a mocked Puppet Enterprise ENC' do
  before(:all) do
    @result = OctocatalogDiff::Integration.integration(
      enc_datafile: 'puppet-enterprise-enc.yaml',
      spec_repo_new: 'pe-enc',
      spec_fact_file: 'facts.yaml',
      spec_catalog_old: 'catalog-empty.json',
      argv: []
    )
  end

  after(:all) do
    if @result[:options] && @result[:options][:enc] && File.file?(@result[:options][:enc])
      FileUtils.rm @result[:options][:enc]
    end
  end

  it 'should run without an error' do
    expect(@result[:exitcode]).not_to eq(-1), "Internal error: #{OctocatalogDiff::Integration.format_exception(@result)}"
    expect(@result[:exitcode]).to eq(2), "Runtime error: #{@result[:logs]}"
  end

  it 'should have /tmp/bar with variable from ENC' do
    pending 'catalog-diff failed' unless @result[:exitcode] == 2
    obj = @result[:diffs].select { |x| x[1] == "File\f/tmp/bar" }
    expect(obj.size).to eq(1), @result[:diffs].map(&:inspect).join("\n")
    expect(obj[0][2]['parameters']['content']).to eq('This bar_variable came from the ENC')
  end

  it 'should have /tmp/baz with no variable' do
    pending 'catalog-diff failed' unless @result[:exitcode] == 2
    obj = @result[:diffs].select { |x| x[1] == "File\f/tmp/baz" }
    expect(obj.size).to eq(1), @result[:diffs].map(&:inspect).join("\n")
    expect(obj[0][2]['parameters']['content']).to eq('not set')
  end

  it 'should have /tmp/foo with variable from ENC' do
    pending 'catalog-diff failed' unless @result[:exitcode] == 2
    obj = @result[:diffs].select { |x| x[1] == "File\f/tmp/foo" }
    expect(obj.size).to eq(1), @result[:diffs].map(&:inspect).join("\n")
    expect(obj[0][2]['parameters']['content']).to eq('This foo_param came from the ENC')
  end
end

describe 'with an actual Puppet Enterprise ENC and SSL client auth' do
  before(:all) do
    opts = {
      ca_file: OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'),
      client_verify: true,
      handler: OctocatalogDiff::PuppetEnterpriseENCIntegration::Handler
    }
    @server = OctocatalogDiff::PuppetEnterpriseENCIntegration::Server.new(opts)
    @pe_enc = "localhost:#{@server.port}"
  end

  after(:all) do
    @server.stop
  end

  # This is a test to ensure that the SSL server is actually requiring client authentication.
  # This catalog compilation should fail (quickly) since no client auth data is provided.
  it 'should fail with no SSL certificate details' do
    opts = {
      spec_repo_new: 'pe-enc',
      spec_fact_file: 'facts.yaml',
      spec_catalog_old: 'catalog-empty.json',
      argv: [
        '--pe-enc-url', "https://#{@pe_enc}/classifier-api"
      ]
    }
    result = OctocatalogDiff::Integration.integration(opts)
    expect(result[:exitcode]).to eq(-1)
    expect(result[:exception].class.to_s).to eq('OpenSSL::SSL::SSLError')
  end

  # Make sure the catalog compiles with data taken from the ENC
  it 'should pull data from ENC' do
    opts = {
      spec_repo_new: 'pe-enc',
      spec_fact_file: 'facts.yaml',
      spec_catalog_old: 'catalog-empty.json',
      argv: [
        '--pe-enc-url', "https://#{@pe_enc}/classifier-api",
        '--pe-enc-ssl-ca', OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'),
        '--pe-enc-ssl-client-cert', OctocatalogDiff::Spec.fixture_path('ssl/generated/client.crt'),
        '--pe-enc-ssl-client-key', OctocatalogDiff::Spec.fixture_path('ssl/generated/client.key')
      ]
    }
    result = OctocatalogDiff::Integration.integration(opts)

    expect(result[:exitcode]).not_to eq(-1), "Internal error: #{OctocatalogDiff::Integration.format_exception(result)}"
    expect(result[:exitcode]).to eq(2), "Runtime error: #{result[:logs]}"

    obj = result[:diffs].select { |x| x[1] == "File\f/tmp/bar" }
    expect(obj.size).to eq(1), result[:diffs].map(&:inspect).join("\n")
    expect(obj[0][2]['parameters']['content']).to eq('This bar_variable came from the ENC')

    obj = result[:diffs].select { |x| x[1] == "File\f/tmp/baz" }
    expect(obj.size).to eq(1), result[:diffs].map(&:inspect).join("\n")
    expect(obj[0][2]['parameters']['content']).to eq('not set')

    obj = result[:diffs].select { |x| x[1] == "File\f/tmp/foo" }
    expect(obj.size).to eq(1), result[:diffs].map(&:inspect).join("\n")
    expect(obj[0][2]['parameters']['content']).to eq('This foo_param came from the ENC')
  end
end

describe 'with an actual Puppet Enterprise ENC and token auth' do
  before(:all) do
    opts = {
      ca_file: OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'),
      client_verify: false,
      handler: OctocatalogDiff::PuppetEnterpriseENCIntegration::Handler,
      require_header: { 'X-Authentication' => 'my-token-would-go-here' }
    }
    @server = OctocatalogDiff::PuppetEnterpriseENCIntegration::Server.new(opts)
    @pe_enc = "localhost:#{@server.port}"
  end

  after(:all) do
    @server.stop
  end

  # This is a test to ensure that the SSL server is actually requiring a token.
  # This catalog compilation should fail (quickly) since no client auth data is provided.
  it 'should fail with no token' do
    opts = {
      spec_repo_new: 'pe-enc',
      spec_fact_file: 'facts.yaml',
      spec_catalog_old: 'catalog-empty.json',
      argv: [
        '--pe-enc-url', "https://#{@pe_enc}/classifier-api"
      ]
    }
    result = OctocatalogDiff::Integration.integration(opts)
    expect(result[:exitcode]).to eq(-1)
    expect(result[:exception].class.to_s).to eq('RuntimeError')
    expect(result[:exception].message).to match(/Failed ENC: Response from https:.+rspec-node.xyz.github.net was 403/)
  end

  # This is a test to ensure that the SSL server is actually requiring a token.
  # This catalog compilation should fail (quickly) since no client auth data is provided.
  it 'should fail with wrong token' do
    opts = {
      spec_repo_new: 'pe-enc',
      spec_fact_file: 'facts.yaml',
      spec_catalog_old: 'catalog-empty.json',
      argv: [
        '--pe-enc-url', "https://#{@pe_enc}/classifier-api",
        '--pe-enc-token', 'this is not the correct token'
      ]
    }
    result = OctocatalogDiff::Integration.integration(opts)
    expect(result[:exitcode]).to eq(-1)
    expect(result[:exception].class.to_s).to eq('RuntimeError')
    expect(result[:exception].message).to match(/Failed ENC: Response from https:.+rspec-node.xyz.github.net was 403/)
  end

  # Make sure the catalog compiles with data taken from the ENC
  it 'should pull data from ENC' do
    opts = {
      spec_repo_new: 'pe-enc',
      spec_fact_file: 'facts.yaml',
      spec_catalog_old: 'catalog-empty.json',
      argv: [
        '--pe-enc-url', "https://#{@pe_enc}/classifier-api",
        '--pe-enc-token', 'my-token-would-go-here'
      ]
    }
    result = OctocatalogDiff::Integration.integration(opts)

    expect(result[:exitcode]).not_to eq(-1), "Internal error: #{OctocatalogDiff::Integration.format_exception(result)}"
    expect(result[:exitcode]).to eq(2), "Runtime error: #{result[:logs]}"

    obj = result[:diffs].select { |x| x[1] == "File\f/tmp/bar" }
    expect(obj.size).to eq(1), result[:diffs].map(&:inspect).join("\n")
    expect(obj[0][2]['parameters']['content']).to eq('This bar_variable came from the ENC')

    obj = result[:diffs].select { |x| x[1] == "File\f/tmp/baz" }
    expect(obj.size).to eq(1), result[:diffs].map(&:inspect).join("\n")
    expect(obj[0][2]['parameters']['content']).to eq('not set')

    obj = result[:diffs].select { |x| x[1] == "File\f/tmp/foo" }
    expect(obj.size).to eq(1), result[:diffs].map(&:inspect).join("\n")
    expect(obj[0][2]['parameters']['content']).to eq('This foo_param came from the ENC')
  end
end
