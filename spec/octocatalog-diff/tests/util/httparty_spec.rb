require_relative '../spec_helper'
require OctocatalogDiff::Spec.require_path('/util/httparty')

describe OctocatalogDiff::Util::HTTParty do
  def mock_get(url, options, code, body, headers)
    obj = double('HTTParty')
    allow(obj).to receive(:code).and_return(code)
    allow(obj).to receive(:body).and_return(body)
    allow(obj).to receive(:headers).and_return(headers)
    allow(::HTTParty).to receive(:get).with(url, options).and_return(obj)
  end

  def mock_post(url, options, code, body, headers)
    obj = double('HTTParty')
    allow(obj).to receive(:code).and_return(code)
    allow(obj).to receive(:body).and_return(body)
    allow(obj).to receive(:headers).and_return(headers)
    allow(::HTTParty).to receive(:post).with(url, options.merge(body: 'xxx')).and_return(obj)
  end

  describe '#get' do
    it 'should return parsed response from httparty GET json' do
      url = 'https://bogus.domain/foobar'
      options = {}
      mock_get(url, options, 200, '{"hello":"world"}', 'content-type' => 'application/json')
      response = OctocatalogDiff::Util::HTTParty.get(url, options)
      expect(response[:code]).to eq(200)
      expect(response[:body]).to eq('{"hello":"world"}')
      expect(response[:parsed]).to eq('hello' => 'world')
    end
  end

  describe '#post' do
    it 'should return parsed response from httparty POST' do
      url = 'https://bogus.domain/foobar'
      options = {}
      mock_post(url, options, 200, '{"hello":"world"}', 'content-type' => 'application/json')
      response = OctocatalogDiff::Util::HTTParty.post(url, options, 'xxx', nil)
      expect(response[:code]).to eq(200)
      expect(response[:body]).to eq('{"hello":"world"}')
      expect(response[:parsed]).to eq('hello' => 'world')
    end
  end

  describe '#httparty_response_parse' do
    context 'response code != 200' do
      it 'should return body if response is JSON with no error' do
        resp = double('HTTParty')
        allow(resp).to receive(:body).and_return('{"hello":"world"}')
        allow(resp).to receive(:code).and_return(499)
        result = OctocatalogDiff::Util::HTTParty.httparty_response_parse(resp)
        expect(result).to eq(code: 499, body: '{"hello":"world"}', error: '{"hello":"world"}')
      end

      it 'should return error if response is JSON with error' do
        resp = double('HTTParty')
        allow(resp).to receive(:body).and_return('{"error":"chicken"}')
        allow(resp).to receive(:code).and_return(499)
        result = OctocatalogDiff::Util::HTTParty.httparty_response_parse(resp)
        expect(result).to eq(code: 499, body: '{"error":"chicken"}', error: 'chicken')
      end

      it 'should return body if body is not JSON' do
        resp = double('HTTParty')
        allow(resp).to receive(:body).and_return('this is not json')
        allow(resp).to receive(:code).and_return(499)
        result = OctocatalogDiff::Util::HTTParty.httparty_response_parse(resp)
        expect(result).to eq(code: 499, body: 'this is not json', error: 'this is not json')
      end
    end

    context 'response code == 200' do
      context 'with content-type header' do
        context 'as JSON' do
          it 'should return parsed JSON' do
            resp = double('HTTParty')
            allow(resp).to receive(:body).and_return('{"hello":"world"}')
            allow(resp).to receive(:code).and_return(200)
            allow(resp).to receive(:headers).and_return('content-type' => 'application/json')
            result = OctocatalogDiff::Util::HTTParty.httparty_response_parse(resp)
            expect(result).to eq(code: 200, body: '{"hello":"world"}', parsed: { 'hello' => 'world' })
          end

          it 'should return error if JSON does not parse' do
            resp = double('HTTParty')
            allow(resp).to receive(:body).and_return('this is not json')
            allow(resp).to receive(:code).and_return(200)
            allow(resp).to receive(:headers).and_return('content-type' => 'application/json')
            result = OctocatalogDiff::Util::HTTParty.httparty_response_parse(resp)
            expect(result[:code]).to eq(500)
            expect(result[:body]).to eq('this is not json')
            expect(result.key?(:parsed)).to eq(false)
            expect(result[:error]).to match(/JSON parse error:/)
          end
        end

        context 'as PSON' do
          it 'should return parsed PSON' do
            resp = double('HTTParty')
            allow(resp).to receive(:body).and_return('{"hello":"world"}')
            allow(resp).to receive(:code).and_return(200)
            allow(resp).to receive(:headers).and_return('content-type' => 'application/pson')
            result = OctocatalogDiff::Util::HTTParty.httparty_response_parse(resp)
            expect(result).to eq(code: 200, body: '{"hello":"world"}', parsed: { 'hello' => 'world' })
          end

          it 'should return error if PSON does not parse' do
            resp = double('HTTParty')
            allow(resp).to receive(:body).and_return('this is not json')
            allow(resp).to receive(:code).and_return(200)
            allow(resp).to receive(:headers).and_return('content-type' => 'application/pson')
            result = OctocatalogDiff::Util::HTTParty.httparty_response_parse(resp)
            expect(result[:code]).to eq(500)
            expect(result[:body]).to eq('this is not json')
            expect(result.key?(:parsed)).to eq(false)
            expect(result[:error]).to match(/PSON parse error:/)
          end
        end

        context 'as something else' do
          it 'should return error' do
            resp = double('HTTParty')
            allow(resp).to receive(:body).and_return('{"hello":"world"}')
            allow(resp).to receive(:code).and_return(200)
            allow(resp).to receive(:headers).and_return('content-type' => 'wub wub wub')
            result = OctocatalogDiff::Util::HTTParty.httparty_response_parse(resp)
            expect(result).to eq(code: 500, body: '{"hello":"world"}', error: "Don't know how to parse: wub wub wub")
          end
        end
      end

      context 'without content-type header' do
        it 'should return raw content' do
          resp = double('HTTParty')
          allow(resp).to receive(:body).and_return('{"hello":"world"}')
          allow(resp).to receive(:code).and_return(200)
          allow(resp).to receive(:headers).and_return({})
          result = OctocatalogDiff::Util::HTTParty.httparty_response_parse(resp)
          expect(result).to eq(code: 200, body: '{"hello":"world"}')
        end
      end
    end
  end

  describe '#wrap_ssl_options' do
    let(:ca_file) { OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt') }
    let(:client_cert) { File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client.crt')) }
    let(:client_key) { File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client.key')) }

    it 'should return empty hash if prefix is undefined' do
      opts = { ssl_ca: ca_file, ssl_client_cert: client_cert, ssl_client_key: client_key }
      result = OctocatalogDiff::Util::HTTParty.wrap_ssl_options(opts, nil)
      expect(result).to eq({})
    end

    it 'should strip prefix and return SSL options' do
      opts = { test_ssl_ca: ca_file, test_ssl_client_cert: client_cert, test_ssl_client_key: client_key }
      result = OctocatalogDiff::Util::HTTParty.wrap_ssl_options(opts, 'test')
      expect(result).to eq(verify: true, ssl_ca_file: ca_file, pem: "#{client_key}#{client_cert}")
    end
  end

  describe '#ssl_options' do
    let(:ca_file) { OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt') }
    let(:client_cert) { File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client.crt')) }
    let(:client_key) { File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client.key')) }
    let(:client_p12) { File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client.p12')) }
    let(:client_pass_cert) { File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client-password.crt')) }
    let(:client_pass_key) { File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client-password.key')) }

    it 'should set raise error when ssl_verify==true but no SSL CA is passed' do
      opts = { ssl_verify: true }
      expect { OctocatalogDiff::Util::HTTParty.ssl_options(opts) }.to raise_error(ArgumentError, /:ssl_ca must be passed/)
    end

    it 'should set verify=false when ssl_verify==false' do
      opts = { ssl_verify: false, ssl_ca: ca_file }
      result = OctocatalogDiff::Util::HTTParty.ssl_options(opts)
      expect(result[:verify]).to eq(false)
    end

    it 'should set verify=true when CA cert is passed' do
      opts = { ssl_ca: ca_file }
      result = OctocatalogDiff::Util::HTTParty.ssl_options(opts)
      expect(result[:verify]).to eq(true)
      expect(result[:ssl_ca_file]).to eq(ca_file)
    end

    it 'should raise error if invalid CA cert is passed' do
      opts = { ssl_ca: "#{ca_file}doesnotexist" }
      expect { OctocatalogDiff::Util::HTTParty.ssl_options(opts) }.to raise_error(Errno::ENOENT, /doesnotexist' not a file/)
    end

    it 'should raise error if SSL client auth is forced to true but no keypair is provided' do
      opts = { ssl_ca: ca_file, ssl_client_auth: true }
      expect { OctocatalogDiff::Util::HTTParty.ssl_options(opts) }.to raise_error(ArgumentError, /SSL client auth enabled/)
    end

    it 'should suppress client auth if ssl_client_auth == false' do
      opts = { ssl_ca: ca_file, ssl_client_auth: false, ssl_client_key: client_key, ssl_client_cert: client_cert }
      result = OctocatalogDiff::Util::HTTParty.ssl_options(opts)
      expect(result).to eq(ssl_ca_file: ca_file, verify: true)
    end

    it 'should construct pem from key + cert' do
      opts = { ssl_ca: ca_file, ssl_client_key: client_key, ssl_client_cert: client_cert }
      result = OctocatalogDiff::Util::HTTParty.ssl_options(opts)
      expect(result).to eq(ssl_ca_file: ca_file, verify: true, pem: "#{client_key}#{client_cert}")
    end

    it 'should construct pem from pem' do
      opts = { ssl_ca: ca_file, ssl_client_pem: "#{client_key}#{client_cert}" }
      result = OctocatalogDiff::Util::HTTParty.ssl_options(opts)
      expect(result).to eq(ssl_ca_file: ca_file, verify: true, pem: "#{client_key}#{client_cert}")
    end

    it 'should raise error if pkcs12 certificate is given without a password' do
      opts = { ssl_ca: ca_file, ssl_client_p12: client_p12 }
      expect { OctocatalogDiff::Util::HTTParty.ssl_options(opts) }.to raise_error(ArgumentError, /pkcs12 requires a password/)
    end

    it 'should allow pkcs12 certificate with a password' do
      opts = { ssl_ca: ca_file, ssl_client_p12: client_p12, ssl_client_password: 'password' }
      result = OctocatalogDiff::Util::HTTParty.ssl_options(opts)
      expect(result).to eq(ssl_ca_file: ca_file, verify: true, p12: client_p12, p12_password: 'password')
    end

    it 'should raise error if PEM requiring password does not have one' do
      opts = { ssl_ca: ca_file, ssl_client_pem: "#{client_pass_key}#{client_pass_cert}" }
      expect { OctocatalogDiff::Util::HTTParty.ssl_options(opts) }.to raise_error(OpenSSL::PKey::RSAError)
    end

    it 'should raise error if PEM requiring password has the wrong password' do
      pem = "#{client_pass_key}#{client_pass_cert}"
      opts = { ssl_ca: ca_file, ssl_client_pem: pem, ssl_client_password: 'incorrect' }
      expect { OctocatalogDiff::Util::HTTParty.ssl_options(opts) }.to raise_error(OpenSSL::PKey::RSAError)
    end

    it 'should allow PEM requiring password with a password' do
      pem = "#{client_pass_key}#{client_pass_cert}"
      opts = { ssl_ca: ca_file, ssl_client_pem: pem, ssl_client_password: 'password' }
      result = OctocatalogDiff::Util::HTTParty.ssl_options(opts)
      expect(result).to eq(ssl_ca_file: ca_file, verify: true, pem: pem, pem_password: 'password')
    end
  end
end
