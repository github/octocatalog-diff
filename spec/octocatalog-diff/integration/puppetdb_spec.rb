# frozen_string_literal: true

require_relative 'integration_helper'

url_map = {
  '/pdb/query/v4/nodes/rspec-node.github.net/facts' => OctocatalogDiff::Spec.mock_puppetdb_fact_response('valid-facts')
}

# Note: string representations of classes here are used to avoid loading all of the libraries
# that throw those error classes.

describe 'puppetdb general tests' do
  it 'should compile with unauthenticated puppetdb' do
    s_opts = { client_verify: false, url_map: url_map }
    opts = { argv: ['-n', 'rspec-node.github.net'], spec_repo: 'tiny-repo' }
    result = OctocatalogDiff::Integration.integration_with_puppetdb(s_opts, opts)
    expect(result[:exitcode]).to eq(0), OctocatalogDiff::Integration.format_exception(result)
  end

  it 'should fail when facts are not found' do
    s_opts = { client_verify: false, url_map: url_map }
    opts = { argv: ['-n', 'not-found-node.github.net'], spec_repo: 'tiny-repo' }
    result = OctocatalogDiff::Integration.integration_with_puppetdb(s_opts, opts)
    expect(result[:exitcode]).to eq(-1), OctocatalogDiff::Integration.format_exception(result)
    expect(result[:exception].class.to_s).to eq('OctocatalogDiff::Errors::CatalogError')
    expect(result[:exception].message).to match(/FactRetrievalError: Node not-found-node.github.net not found in PuppetDB/)
  end
end

describe 'puppetdb ssl' do
  context 'certificate verification' do
    it 'should validate a properly signed server certificate', retry: 3 do
      args = [
        '-n', 'rspec-node.github.net',
        '--puppetdb-ssl-ca', OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt')
      ]
      s_opts = { client_verify: false, url_map: url_map }
      opts = { argv: args, spec_repo: 'tiny-repo' }
      result = OctocatalogDiff::Integration.integration_with_puppetdb(s_opts, opts)
      expect(result[:exitcode]).to eq(0), OctocatalogDiff::Integration.format_exception(result)
    end

    it 'should fail if server certificate does not match hostname', retry: 3 do
      s_opts = {
        client_verify: false,
        url_map: url_map,
        cert: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/bogushost.crt'))
      }
      args = [
        '-n', 'rspec-node.github.net',
        '--puppetdb-ssl-ca', OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt')
      ]
      opts = { argv: args, spec_repo: 'tiny-repo' }
      result = OctocatalogDiff::Integration.integration_with_puppetdb(s_opts, opts)
      expect(result[:exitcode]).to eq(-1), OctocatalogDiff::Integration.format_exception(result)
      expect(result[:exception].class.to_s).to eq('OctocatalogDiff::Errors::CatalogError')
      expect(result[:exception].message).to match(/OpenSSL::SSL::SSLError/)
    end

    it 'should fail if server certificate was not signed by CA', retry: 3 do
      s_opts = {
        client_verify: false,
        url_map: url_map,
        cert: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client-other-ca.crt')),
        rsa_key: File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client.key'))
      }
      args = [
        '-n', 'rspec-node.github.net',
        '--puppetdb-ssl-ca', OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt')
      ]
      opts = { argv: args, spec_repo: 'tiny-repo' }
      result = OctocatalogDiff::Integration.integration_with_puppetdb(s_opts, opts)
      expect(result[:exitcode]).to eq(-1), OctocatalogDiff::Integration.format_exception(result)
      expect(result[:exception].class.to_s).to eq('OctocatalogDiff::Errors::CatalogError')
      expect(result[:exception].message).to match(/OpenSSL::SSL::SSLError/)
    end
  end

  context 'client certificate authentication' do
    let(:s_opts) do
      {
        ca_file: OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'),
        client_verify: true,
        url_map: url_map
      }
    end

    it 'should fail to connect to authenticated puppetdb with no client cert', retry: 3 do
      opts = { argv: ['-n', 'rspec-node.github.net'], spec_repo: 'tiny-repo' }
      result = OctocatalogDiff::Integration.integration_with_puppetdb(s_opts, opts)
      expect(result[:exception].class.to_s).to eq('OctocatalogDiff::Errors::CatalogError')
      expect(result[:exception].message).to match(/OpenSSL::SSL::SSLError/)
    end

    it 'should connect to authenticated puppetdb with client keypair', retry: 3 do
      args = [
        '-n', 'rspec-node.github.net',
        '--puppetdb-ssl-ca', OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'),
        '--puppetdb-ssl-client-cert', OctocatalogDiff::Spec.fixture_path('ssl/generated/client.crt'),
        '--puppetdb-ssl-client-key', OctocatalogDiff::Spec.fixture_path('ssl/generated/client.key')
      ]
      opts = { argv: args, spec_repo: 'tiny-repo' }
      result = OctocatalogDiff::Integration.integration_with_puppetdb(s_opts, opts)
      expect(result[:exitcode]).to eq(0), OctocatalogDiff::Integration.format_exception(result)
    end

    it 'should compile with password-protected client cert to authenticated puppetdb', retry: 3 do
      args = [
        '-n', 'rspec-node.github.net',
        '--puppetdb-ssl-ca', OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt'),
        '--puppetdb-ssl-client-cert', OctocatalogDiff::Spec.fixture_path('ssl/generated/client-password.crt'),
        '--puppetdb-ssl-client-key', OctocatalogDiff::Spec.fixture_path('ssl/generated/client-password.key'),
        '--puppetdb-ssl-client-password', 'password'
      ]
      opts = { argv: args, spec_repo: 'tiny-repo' }
      result = OctocatalogDiff::Integration.integration_with_puppetdb(s_opts, opts)
      expect(result[:exitcode]).to eq(0), OctocatalogDiff::Integration.format_exception(result)
    end

    it 'should fail with password-protected client cert and wrong password to authenticated puppetdb', retry: 3 do
      arg = [
        '-n', 'rspec-node.github.net',
        '--puppetdb-ssl-client-cert', OctocatalogDiff::Spec.fixture_path('ssl/generated/client-password.crt'),
        '--puppetdb-ssl-client-key', OctocatalogDiff::Spec.fixture_path('ssl/generated/client-password.key'),
        '--puppetdb-ssl-client-password', 'wrong-password'
      ]
      opts = { argv: arg, spec_repo: 'tiny-repo' }
      result = OctocatalogDiff::Integration.integration_with_puppetdb(s_opts, opts)
      expect(result[:exitcode]).to eq(-1), OctocatalogDiff::Integration.format_exception(result)
      expect(result[:exception].class.to_s).to eq('OctocatalogDiff::Errors::CatalogError')
      expect(result[:exception].message).to match(/OpenSSL::PKey::RSAError/)
    end

    it 'should fail with password-protected client cert and missing password to authenticated puppetdb', retry: 3 do
      arg = [
        '-n', 'rspec-node.github.net',
        '--puppetdb-ssl-client-cert', OctocatalogDiff::Spec.fixture_path('ssl/generated/client-password.crt'),
        '--puppetdb-ssl-client-key', OctocatalogDiff::Spec.fixture_path('ssl/generated/client-password.key')
      ]
      opts = { argv: arg, spec_repo: 'tiny-repo' }
      result = OctocatalogDiff::Integration.integration_with_puppetdb(s_opts, opts)
      expect(result[:exitcode]).to eq(-1), OctocatalogDiff::Integration.format_exception(result)
      expect(result[:exception].class.to_s).to eq('OctocatalogDiff::Errors::CatalogError')
      expect(result[:exception].message).to match(/OpenSSL::PKey::RSAError/)
    end
  end
end
