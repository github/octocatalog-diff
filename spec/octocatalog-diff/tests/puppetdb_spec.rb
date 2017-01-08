# frozen_string_literal: true

# Test the OctocatalogDiff::PuppetDB library
require_relative 'spec_helper'
require OctocatalogDiff::Spec.require_path('/errors')
require OctocatalogDiff::Spec.require_path('/puppetdb')
require 'uri'

PUPPETDB_NOSSL_PORT = 8080
PUPPETDB_SSL_PORT = 8081

def ssl_test(server_opts, opts = {})
  server_opts[:rsa_key] ||= File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/server.key'))
  server_opts[:cert] ||= File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/server.crt'))
  test_server = nil
  3.times do
    test_server = SSLTestServer.new(server_opts)
    test_server.start
    break if test_server.port > 0
  end
  raise OctocatalogDiff::Spec::FixtureError, 'Unable to instantiate SSLTestServer' unless test_server.port > 0
  testobj = OctocatalogDiff::PuppetDB.new(opts.merge(puppetdb_url: "https://localhost:#{test_server.port}"))
  return testobj.get('/foo')
ensure
  test_server.stop
end

describe OctocatalogDiff::PuppetDB do
  # Test constructor's ability to create @connections
  describe '#initialize' do
    before(:each) do
      %w(PUPPETDB_URL PUPPETDB_HOST PUPPETDB_PORT PUPPETDB_SSL).each { |key| ENV.delete(key) }
    end

    context 'one :puppetdb_url' do
      it 'should construct one connection' do
        opts = { puppetdb_url: 'https://foo.bar.host:8090' }
        answer = { ssl: true, host: 'foo.bar.host', port: 8090 }
        testobj = OctocatalogDiff::PuppetDB.new(opts)
        expect(testobj.connections.size).to eq(1)
        expect(testobj.connections.first).to eq(answer)
      end
    end

    context 'multiple :puppetdb_url' do
      it 'should construct array of connections' do
        opts = { puppetdb_url: ['https://foo.bar.host:8090', 'http://fizz.buzz:1234'] }
        answer0 = { ssl: true, host: 'foo.bar.host', port: 8090 }
        answer1 = { ssl: false, host: 'fizz.buzz', port: 1234 }
        testobj = OctocatalogDiff::PuppetDB.new(opts)
        expect(testobj.connections.size).to eq(2)
        expect(testobj.connections[0]).to eq(answer0)
        expect(testobj.connections[1]).to eq(answer1)
      end
    end

    context 'one :puppetdb_host' do
      it 'should construct connection from hostname + ssl + port' do
        opts = { puppetdb_host: 'foo.bar.host', puppetdb_port: 8090, puppetdb_ssl: true }
        answer = { ssl: true, host: 'foo.bar.host', port: 8090 }
        testobj = OctocatalogDiff::PuppetDB.new(opts)
        expect(testobj.connections.size).to eq(1)
        expect(testobj.connections.first).to eq(answer)
      end

      it 'should construct connection from hostname + ssl == true' do
        opts = { puppetdb_host: 'foo.bar.host', puppetdb_ssl: true }
        answer = { ssl: true, host: 'foo.bar.host', port: PUPPETDB_SSL_PORT }
        testobj = OctocatalogDiff::PuppetDB.new(opts)
        expect(testobj.connections.size).to eq(1)
        expect(testobj.connections.first).to eq(answer)
      end

      it 'should construct connection from hostname + ssl == false' do
        opts = { puppetdb_host: 'foo.bar.host', puppetdb_ssl: false }
        testobj = OctocatalogDiff::PuppetDB.new(opts)
        answer = { ssl: false, host: 'foo.bar.host', port: PUPPETDB_NOSSL_PORT }
        expect(testobj.connections.size).to eq(1)
        expect(testobj.connections.first).to eq(answer)
      end

      it 'should default to ssl == true' do
        opts = { puppetdb_host: 'foo.bar.host', puppetdb_port: 8090 }
        testobj = OctocatalogDiff::PuppetDB.new(opts)
        answer = { ssl: true, host: 'foo.bar.host', port: 8090 }
        expect(testobj.connections.size).to eq(1)
        expect(testobj.connections.first).to eq(answer)
      end

      it 'should construct connection from just hostname' do
        opts = { puppetdb_host: 'foo.bar.host' }
        testobj = OctocatalogDiff::PuppetDB.new(opts)
        answer = { ssl: true, host: 'foo.bar.host', port: PUPPETDB_SSL_PORT }
        expect(testobj.connections.size).to eq(1)
        expect(testobj.connections.first).to eq(answer)
      end
    end

    context 'environment PUPPETDB_URL' do
      it 'should recognize PUPPETDB_URL from environment' do
        ENV['PUPPETDB_URL'] = 'http://puppetdb.url.host'
        answer = { ssl: false, host: 'puppetdb.url.host', port: PUPPETDB_NOSSL_PORT }
        testobj = OctocatalogDiff::PuppetDB.new({})
        expect(testobj.connections.first).to eq(answer)
      end
    end

    context 'environment PUPPETDB_HOST' do
      it 'should recognize PUPPETDB_HOST from environment' do
        ENV['PUPPETDB_HOST'] = 'puppetdb.host.host'
        answer = { ssl: true, host: 'puppetdb.host.host', port: PUPPETDB_SSL_PORT }
        testobj = OctocatalogDiff::PuppetDB.new({})
        expect(testobj.connections.first).to eq(answer)
      end

      it 'should recognize PUPPETDB_SSL from environment' do
        ENV['PUPPETDB_HOST'] = 'puppetdb.host.host'
        ENV['PUPPETDB_SSL'] = 'false' # Env vars are strings
        answer = { ssl: false, host: 'puppetdb.host.host', port: PUPPETDB_NOSSL_PORT }
        testobj = OctocatalogDiff::PuppetDB.new({})
        expect(testobj.connections.first).to eq(answer)
      end

      it 'should recognize PUPPETDB_PORT from environment' do
        ENV['PUPPETDB_HOST'] = 'puppetdb.host.host'
        ENV['PUPPETDB_PORT'] = '1234' # Env vars are strings
        answer = { ssl: true, host: 'puppetdb.host.host', port: 1234 }
        testobj = OctocatalogDiff::PuppetDB.new({})
        expect(testobj.connections.first).to eq(answer)
      end
    end

    context 'order of precedence' do
      it 'should prioritize :puppetdb_url before :puppetdb_host' do
        opts = {
          puppetdb_url: 'http://puppetdb.url.host',
          puppetdb_host: 'puppetdb.host.host'
        }
        answer = { ssl: false, host: 'puppetdb.url.host', port: PUPPETDB_NOSSL_PORT }
        testobj = OctocatalogDiff::PuppetDB.new(opts)
        expect(testobj.connections.first).to eq(answer)
      end

      it 'should prioritize :puppetdb_host before ENV["PUPPETDB_URL"]' do
        opts = {
          puppetdb_host: 'puppetdb.host.host'
        }
        ENV['PUPPETDB_URL'] = 'http://puppetdb.url.host'
        answer = { ssl: true, host: 'puppetdb.host.host', port: PUPPETDB_SSL_PORT }
        testobj = OctocatalogDiff::PuppetDB.new(opts)
        expect(testobj.connections.first).to eq(answer)
      end

      it 'should prioritize ENV["PUPPETDB_URL"] before ENV["PUPPETDB_HOST"]' do
        ENV['PUPPETDB_HOST'] = 'puppetdb.host.host'
        ENV['PUPPETDB_URL'] = 'http://puppetdb.url.host'
        answer = { ssl: false, host: 'puppetdb.url.host', port: PUPPETDB_NOSSL_PORT }
        testobj = OctocatalogDiff::PuppetDB.new({})
        expect(testobj.connections.first).to eq(answer)
      end
    end
  end

  # httparty get wrapper
  describe '#get' do
    it 'should raise error if no connections are configured' do
      %w(PUPPETDB_URL PUPPETDB_HOST PUPPETDB_PORT PUPPETDB_SSL).each { |key| ENV.delete(key) }
      testobj = OctocatalogDiff::PuppetDB.new({})
      expect { testobj.get('/foo') }.to raise_error(ArgumentError)
    end

    it 'should raise connection error' do
      opts = {
        timeout: 1,
        puppetdb_url: 'http://127.0.0.1:1'
      }
      testobj = OctocatalogDiff::PuppetDB.new(opts)
      expect { testobj.get('/foo') }.to raise_error(OctocatalogDiff::Errors::PuppetDBConnectionError)
    end

    it 'should timeout correctly' do
      # Timed test here, because we are testing the 1 second timeout.
      # Will give a buffer for possible slowness on the machine and test
      # that this is less than or equal to 5 seconds.
      opts = {
        timeout: 1,
        puppetdb_url: 'http://0.0.0.0:1'
      }
      testobj = OctocatalogDiff::PuppetDB.new(opts)
      time_begin = Time.now.to_i
      expect { testobj.get('/foo') }.to raise_error(OctocatalogDiff::Errors::PuppetDBConnectionError)
      time_end = Time.now.to_i
      expect(time_end - time_begin).to be <= 5
    end
  end

  # Unit test on this private method
  describe '#parse_url' do
    before(:each) do
      %w(PUPPETDB_URL PUPPETDB_HOST PUPPETDB_PORT PUPPETDB_SSL).each { |key| ENV.delete(key) }
    end

    context 'protocol detection' do
      it 'should identify https:// URL as having ssl enabled' do
        test_url = 'https://foo.bar.host:8090'
        testobj = OctocatalogDiff::PuppetDB.new
        result = testobj.send(:parse_url, test_url)
        expect(result[:ssl]).to eq(true)
      end

      it 'should identify http:// URL as having ssl disabled' do
        test_url = 'http://foo.bar.host:8090'
        testobj = OctocatalogDiff::PuppetDB.new
        result = testobj.send(:parse_url, test_url)
        expect(result[:ssl]).to eq(false)
      end

      it 'should raise exception if http or https is not used' do
        test_url = 'asdlfk://foo.bar.host:8090'
        testobj = OctocatalogDiff::PuppetDB.new
        expect { testobj.send(:parse_url, test_url) }.to raise_error(ArgumentError)
      end
    end

    context 'hostname determination' do
      it 'should determine hostname if URL has port' do
        test_url = 'https://foo.bar.host:8090'
        testobj = OctocatalogDiff::PuppetDB.new
        result = testobj.send(:parse_url, test_url)
        expect(result[:host]).to eq('foo.bar.host')
      end

      it 'should determine hostname if URL has no port' do
        test_url = 'https://foo.bar.host'
        testobj = OctocatalogDiff::PuppetDB.new
        result = testobj.send(:parse_url, test_url)
        expect(result[:host]).to eq('foo.bar.host')
      end

      it 'should error on invalid url' do
        test_url = 'https://:xyz123'
        testobj = OctocatalogDiff::PuppetDB.new
        expect { testobj.send(:parse_url, test_url) }.to raise_error(URI::InvalidURIError)
      end
    end

    context 'port determination' do
      it 'should use the port number if supplied' do
        test_url = 'https://foo.bar.host:8090'
        testobj = OctocatalogDiff::PuppetDB.new
        result = testobj.send(:parse_url, test_url)
        expect(result[:port]).to eq(8090)
      end

      it 'should default to port 8081 for https' do
        test_url = 'https://foo.bar.host'
        testobj = OctocatalogDiff::PuppetDB.new
        result = testobj.send(:parse_url, test_url)
        expect(result[:port]).to eq(8081)
      end

      it 'should default to port PUPPETDB_NOSSL_PORT for http' do
        test_url = 'http://foo.bar.host'
        testobj = OctocatalogDiff::PuppetDB.new
        result = testobj.send(:parse_url, test_url)
        expect(result[:port]).to eq(PUPPETDB_NOSSL_PORT)
      end

      it 'should error if an invalid port is given' do
        test_url = 'http://foo.bar.host:-2'
        testobj = OctocatalogDiff::PuppetDB.new
        expect { testobj.send(:parse_url, test_url) }.to raise_error(URI::InvalidURIError)
      end
    end
  end

  context 'puppetdb ssl connection options' do
    context 'with ssl verification off' do
      let(:server_opts) { { client_verify: false } }
      let(:client_opts) { { puppetdb_ssl_verify: false } }
      describe '#get' do
        it 'should not fail even when cert is not verifiable' do
          result = ssl_test(server_opts, client_opts)
          expect(result.key?('success')).to eq(true)
        end

        it 'should not raise an error even if the SSL CA file is not available' do
          result = ssl_test(server_opts, client_opts.merge(puppetdb_ssl_ca: OctocatalogDiff::Spec.fixture_path('asdflkasfldk')))
          expect(result.key?('success')).to eq(true)
        end
      end
    end

    context 'with ssl verification on' do
      let(:server_opts) { { client_verify: false } }
      let(:client_opts) { { puppetdb_ssl_verify: true } }
      describe '#get' do
        it 'should verify the cert with the ca cert' do
          opts = client_opts.merge(puppetdb_ssl_ca: OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'))
          result = ssl_test(server_opts, opts)
          expect(result.key?('success')).to eq(true)
        end

        it 'should raise an error if invalid CA file is specified' do
          expect do
            ssl_test(server_opts, client_opts.merge(puppetdb_ssl_ca: OctocatalogDiff::Spec.fixture_path('asdflkasfldk')))
          end.to raise_error(Errno::ENOENT)
        end

        it 'should raise an error if non-matching CA file is specified' do
          opts = client_opts.merge(puppetdb_ssl_ca: OctocatalogDiff::Spec.fixture_path('ssl/generated/other-ca.crt'))
          expect do
            ssl_test(server_opts, opts)
          end.to raise_error(OpenSSL::SSL::SSLError)
        end

        it 'should raise error if server hostname does not match expected' do
          c_opts = client_opts.merge(puppetdb_ssl_ca: OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'))
          s_opts = server_opts.merge(
            rsa_key: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/server.key')),
            cert: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/bogushost.crt'))
          )
          expect do
            ssl_test(s_opts, c_opts)
          end.to raise_error(OpenSSL::SSL::SSLError)
        end
      end
    end
  end

  context 'with client auth' do
    describe '#get' do
      let(:server_opts) do
        {
          client_verify: true,
          ca_file: OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt')
        }
      end
      let(:client_opts) do
        {
          puppetdb_ssl_verify: true,
          puppetdb_ssl_ca: OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt')
        }
      end

      it 'should not authenticate when no client creds are given' do
        expect do
          ssl_test(server_opts, client_opts)
        end.to raise_error(OpenSSL::SSL::SSLError)
      end

      it 'should authenticate when a PEM file is given' do
        opts = {
          puppetdb_ssl_client_pem: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client.pem'))
        }
        result = ssl_test(server_opts, client_opts.merge(opts))
        expect(result.key?('success')).to eq(true)
      end

      it 'should authenticate when a P12 file is given' do
        opts = {
          puppetdb_ssl_ca: OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'),
          puppetdb_ssl_client_p12: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client.p12')),
          puppetdb_ssl_client_password: 'password'
        }
        result = ssl_test(server_opts, client_opts.merge(opts))
        expect(result.key?('success')).to eq(true)
      end

      it 'should raise ArgumentError when a P12 file is given with no password' do
        opts = {
          puppetdb_ssl_ca: OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'),
          puppetdb_ssl_client_p12: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client.p12'))
        }
        expect do
          ssl_test(server_opts, opts)
        end.to raise_error(ArgumentError, /pkcs12 requires a password/)
      end

      it 'should fail when a P12 file is given with the wrong password' do
        opts = {
          puppetdb_ssl_ca: OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'),
          puppetdb_ssl_client_p12: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client.p12')),
          puppetdb_ssl_client_password: 'wrong-password'
        }
        expect do
          ssl_test(server_opts, opts)
        end.to raise_error(OpenSSL::PKCS12::PKCS12Error)
      end

      it 'should authenticate when a key and certificate are given' do
        opts = {
          puppetdb_ssl_ca: OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'),
          puppetdb_ssl_client_cert: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client.crt')),
          puppetdb_ssl_client_key: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client.key'))
        }
        result = ssl_test(server_opts, client_opts.merge(opts))
        expect(result.key?('success')).to eq(true)
      end

      it 'should authenticate when a key and certificate are given (second CA)' do
        opts = {
          puppetdb_ssl_ca: OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'),
          puppetdb_ssl_client_cert: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client-other-ca.crt')),
          puppetdb_ssl_client_key: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client.key'))
        }
        s_opts = { ca_file:  OctocatalogDiff::Spec.fixture_path('ssl/generated/other-ca.crt') }
        result = ssl_test(server_opts.merge(s_opts), client_opts.merge(opts))
        expect(result.key?('success')).to eq(true)
      end

      it 'should not authenticate when a key and certificate signed by a different CA are given' do
        opts = {
          puppetdb_ssl_ca: OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'),
          puppetdb_ssl_client_cert: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client-other-ca.crt')),
          puppetdb_ssl_client_key: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client.key'))
        }
        expect do
          ssl_test(server_opts, opts)
        end.to raise_error(OpenSSL::SSL::SSLError)
      end

      it 'should authenticate when a password protected key is used' do
        opts = {
          puppetdb_ssl_ca: OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'),
          puppetdb_ssl_client_cert: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client-password.crt')),
          puppetdb_ssl_client_key: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client-password.key')),
          puppetdb_ssl_client_password: 'password'
        }
        result = ssl_test(server_opts, client_opts.merge(opts))
        expect(result.key?('success')).to eq(true)
      end

      it 'should not authenticate when the password is wrong' do
        opts = {
          puppetdb_ssl_ca: OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'),
          puppetdb_ssl_client_cert: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client-password.crt')),
          puppetdb_ssl_client_key: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client-password.key')),
          puppetdb_ssl_client_password: 'wrong-password'
        }
        expect do
          ssl_test(server_opts, opts)
        end.to raise_error(OpenSSL::PKey::RSAError)
      end

      it 'should fail if a required password is missing' do
        opts = {
          puppetdb_ssl_ca: OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'),
          puppetdb_ssl_client_cert: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client-password.crt')),
          puppetdb_ssl_client_key: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client-password.key'))
        }
        expect do
          ssl_test(server_opts, opts)
        end.to raise_error(OpenSSL::PKey::RSAError)
      end
    end
  end

  describe '#_get' do
    before(:each) do
      opts = { puppetdb_url: 'https://foo.bar.host:8090' }
      @testobj = OctocatalogDiff::PuppetDB.new(opts)
    end

    it 'should handle 404 responses' do
      allow(OctocatalogDiff::Util::HTTParty).to receive(:get).and_return(code: 404, error: 'oh noez')
      expect { @testobj.send(:get, '/foo') }.to raise_error(OctocatalogDiff::Errors::PuppetDBNodeNotFoundError, /oh noez/)
    end

    it 'should handle !=200, !=404 responses' do
      allow(OctocatalogDiff::Util::HTTParty).to receive(:get).and_return(code: 499, error: 'oh noez')
      expect { @testobj.send(:get, '/foo') }.to raise_error(OctocatalogDiff::Errors::PuppetDBGenericError, /oh noez/)
    end

    it 'should handle responses with :error' do
      allow(OctocatalogDiff::Util::HTTParty).to receive(:get).and_return(code: 200, error: 'oh noez')
      expect { @testobj.send(:get, '/foo') }.to raise_error(OctocatalogDiff::Errors::PuppetDBGenericError, /500 - oh noez/)
    end

    it 'should handle unparseable responses' do
      allow(OctocatalogDiff::Util::HTTParty).to receive(:get).and_return(code: 200)
      expect { @testobj.send(:get, '/foo') }.to raise_error(RuntimeError, /Unparseable response from puppetdb:/)
    end
  end
end
