require_relative '../spec_helper'
require OctocatalogDiff::Spec.require_path('/facts')
require OctocatalogDiff::Spec.require_path('/catalog-util/builddir')
require OctocatalogDiff::Spec.require_path('/catalog-diff/cli/helpers/fact_override')
require 'socket'
require 'yaml'

describe OctocatalogDiff::CatalogUtil::BuildDir do
  describe '#create_structure' do
    it 'should create skeleton structure' do
      options = {
        basedir: OctocatalogDiff::Spec.fixture_path('repos/default'),
        facts_terminus: 'facter' # Skips any fact installation
      }
      logger, _logger_str = OctocatalogDiff::Spec.setup_logger
      testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger)
      expect(File.directory?(File.join(testobj.tempdir, 'environments'))).to eq(true)
      expect(File.directory?(File.join(testobj.tempdir, 'facts'))).to eq(true)
      expect(File.directory?(File.join(testobj.tempdir, 'var'))).to eq(true)
      expect(File.directory?(File.join(testobj.tempdir, 'var/ssl'))).to eq(true)
      expect(File.directory?(File.join(testobj.tempdir, 'var/yaml'))).to eq(true)
      expect(File.directory?(File.join(testobj.tempdir, 'var/yaml/facts'))).to eq(true)
    end
  end

  describe '#install_directory_symlink' do
    it 'should create properly pointed symlink' do
      options = {
        basedir: OctocatalogDiff::Spec.fixture_path('repos/default'),
        facts_terminus: 'facter' # Skips any fact installation
      }
      logger, _logger_str = OctocatalogDiff::Spec.setup_logger
      testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger)
      expect(File.symlink?(File.join(testobj.tempdir, 'environments/production'))).to eq(true)
      symlink_target = File.readlink(File.join(testobj.tempdir, 'environments/production'))
      expect(symlink_target).to eq(OctocatalogDiff::Spec.fixture_path('repos/default'))
    end
  end

  describe '#install_puppetdb_conf' do
    context 'with default timeout' do
      it 'should create puppetdb.conf' do
        options = {
          basedir: OctocatalogDiff::Spec.fixture_path('repos/default'),
          facts_terminus: 'facter', # Skips any fact installation
          puppetdb_url: 'https://1.0.0.1:1'
        }
        logger, _logger_str = OctocatalogDiff::Spec.setup_logger
        testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger)
        expect(File.file?(File.join(testobj.tempdir, 'puppetdb.conf'))).to eq(true)
        content = File.read(File.join(testobj.tempdir, 'puppetdb.conf')).split(/\n/)
        expect(content.size).to eq(3)
        expect(content[0]).to eq('[main]')
        expect(content[1]).to eq('server_urls = https://1.0.0.1:1')
        expect(content[2]).to eq('server_url_timeout = 30')
      end
    end

    context 'with non-default timeout' do
      it 'should create puppetdb.conf' do
        options = {
          basedir: OctocatalogDiff::Spec.fixture_path('repos/default'),
          facts_terminus: 'facter', # Skips any fact installation
          puppetdb_url: 'https://1.0.0.1:1',
          puppetdb_server_url_timeout: 120
        }
        logger, _logger_str = OctocatalogDiff::Spec.setup_logger
        testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger)
        expect(File.file?(File.join(testobj.tempdir, 'puppetdb.conf'))).to eq(true)
        content = File.read(File.join(testobj.tempdir, 'puppetdb.conf')).split(/\n/)
        expect(content.size).to eq(3)
        expect(content[0]).to eq('[main]')
        expect(content[1]).to eq('server_urls = https://1.0.0.1:1')
        expect(content[2]).to eq('server_url_timeout = 120')
      end
    end

    context 'with invalid options' do
      it 'should raise ArgumentError if server_urls is not a string' do
        options = {
          basedir: OctocatalogDiff::Spec.fixture_path('repos/default'),
          facts_terminus: 'facter', # Skips any fact installation
          puppetdb_url: {}
        }
        logger, _logger_str = OctocatalogDiff::Spec.setup_logger
        r = Regexp.new('server_urls must be a string, got a: Hash')
        expect { OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger) }.to raise_error(ArgumentError, r)
      end

      it 'should raise ArgumentError if server_url_timeout is not a fixnum' do
        options = {
          basedir: OctocatalogDiff::Spec.fixture_path('repos/default'),
          facts_terminus: 'facter', # Skips any fact installation
          puppetdb_url: 'https://1.0.0.1:1',
          puppetdb_server_url_timeout: :chicken
        }
        logger, _logger_str = OctocatalogDiff::Spec.setup_logger
        r = Regexp.new('server_url_timeout must be a fixnum, got a: Symbol')
        expect { OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger) }.to raise_error(ArgumentError, r)
      end
    end
  end

  describe '#install_routes_yaml' do
    it 'should create routes.yaml' do
      options = {
        basedir: OctocatalogDiff::Spec.fixture_path('repos/default'),
        facts_terminus: 'facter', # Skips any fact installation
        puppetdb_url: 'https://1.0.0.1:1',
        puppetdb_server_url_timeout: 120
      }
      logger, _logger_str = OctocatalogDiff::Spec.setup_logger
      testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger)
      expect(File.file?(File.join(testobj.tempdir, 'routes.yaml'))).to eq(true)
      content = File.read(File.join(testobj.tempdir, 'routes.yaml')).split(/\n/)
      expect(content.size).to eq(7)
      routes_yaml = YAML.load_file(File.join(testobj.tempdir, 'routes.yaml'))
      expect(routes_yaml).to eq('master' => {
                                  'facts' => { 'terminus' => 'puppetdb', 'cache' => 'yaml' },
                                  'catalog' => { 'cache' => 'json' }
                                })
    end
  end

  describe '#install_hiera_config' do
    let(:default_options) do
      {
        basedir: OctocatalogDiff::Spec.fixture_path('repos/default'),
        facts_terminus: 'facter', # Skips any fact installation
        puppetdb_url: 'https://1.0.0.1:1',
        puppetdb_server_url_timeout: 120
      }
    end
    context 'with relative path' do
      it 'should install the hiera configuration file' do
        options = default_options.merge(hiera_config: 'config/hiera.yaml')
        logger, _logger_str = OctocatalogDiff::Spec.setup_logger
        testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger)
        hiera_yaml = File.join(testobj.tempdir, 'hiera.yaml')
        expect(File.file?(hiera_yaml)).to eq(true)
        hiera_cfg = YAML.load_file(hiera_yaml)
        expect(hiera_cfg[:backends]).to eq(['yaml'])
        expect(hiera_cfg[:yaml]).to eq(datadir: '/var/lib/puppet/environments/production/hieradata')
      end
    end

    context 'with relative path including environments/production' do
      it 'should install the hiera configuration file' do
        options = default_options.merge(hiera_config: 'environments/production/config/hiera.yaml')
        logger, _logger_str = OctocatalogDiff::Spec.setup_logger
        testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger)
        hiera_yaml = File.join(testobj.tempdir, 'hiera.yaml')
        expect(File.file?(hiera_yaml)).to eq(true)
        hiera_cfg = YAML.load_file(hiera_yaml)
        expect(hiera_cfg[:backends]).to eq(['yaml'])
        expect(hiera_cfg[:yaml]).to eq(datadir: '/var/lib/puppet/environments/production/hieradata')
      end
    end

    context 'with absolute path' do
      it 'should install the hiera configuration file' do
        options = default_options.merge(hiera_config: OctocatalogDiff::Spec.fixture_path('repos/default/config/hiera.yaml'))
        logger, _logger_str = OctocatalogDiff::Spec.setup_logger
        testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger)
        hiera_yaml = File.join(testobj.tempdir, 'hiera.yaml')
        expect(File.file?(hiera_yaml)).to eq(true)
        hiera_cfg = YAML.load_file(hiera_yaml)
        expect(hiera_cfg[:backends]).to eq(['yaml'])
        expect(hiera_cfg[:yaml]).to eq(datadir: '/var/lib/puppet/environments/production/hieradata')
      end
    end

    context 'with invalid options' do
      it 'should raise argument error if called with non-string argument' do
        options = {
          basedir: OctocatalogDiff::Spec.fixture_path('repos/default'),
          fact_file: OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml'),
          node: 'rspec-node.github.net'
        }
        logger, _logger_str = OctocatalogDiff::Spec.setup_logger
        r = Regexp.new('Called install_hiera_config with a Symbol argument')
        testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger)
        expect { testobj.send(:install_hiera_config, logger, :chicken, nil) }.to raise_error(ArgumentError, r)
      end
    end
  end

  describe '#install_fact_file' do
    context 'without fact overrides' do
      it 'should create and populate the fact file' do
        options = {
          basedir: OctocatalogDiff::Spec.fixture_path('repos/default'),
          fact_file: OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml'),
          facts_terminus: 'yaml',
          node: 'rspec-node.github.net'
        }
        logger, _logger_str = OctocatalogDiff::Spec.setup_logger
        testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger)
        fact_file = File.join(testobj.tempdir, 'var/yaml/facts/rspec-node.github.net.yaml')
        expect(File.file?(fact_file)).to eq(true)

        yaml_content = File.read(fact_file).split(/\n/)
        expect(yaml_content[0]).to eq('--- !ruby/object:Puppet::Node::Facts')

        yaml_content[0] = '---' # To avoid need for puppet gem
        factobj = YAML.load(yaml_content.join("\n"))
        expect(factobj).to be_a_kind_of(Hash)
        expect(factobj['name']).to eq('rspec-node.github.net')
        expect(factobj['values']).to be_a_kind_of(Hash)
        expect(factobj['values']['clientcert']).to eq('rspec-node.github.net')
        expect(factobj['values']['ipaddress']).to eq('10.20.30.40')
      end

      it 'should return a pre-existing facts object' do
        options = {
          basedir: OctocatalogDiff::Spec.fixture_path('repos/default'),
          node: 'rspec-node.github.net',
          facts: OctocatalogDiff::Facts.new(
            backend: :yaml,
            node: 'foo',
            fact_file_string: File.read(OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml'))
          )
        }
        logger, _logger_str = OctocatalogDiff::Spec.setup_logger
        testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger)
        fact_file = File.join(testobj.tempdir, 'var/yaml/facts/rspec-node.github.net.yaml')
        expect(File.file?(fact_file)).to eq(true)
        yaml_content = File.read(fact_file).split(/\n/)
        expect(yaml_content[0]).to eq('--- !ruby/object:Puppet::Node::Facts')

        yaml_content[0] = '---' # To avoid need for puppet gem
        factobj = YAML.load(yaml_content.join("\n"))
        expect(factobj).to be_a_kind_of(Hash)
        expect(factobj['name']).to eq('rspec-node.github.net')
        expect(factobj['values']).to be_a_kind_of(Hash)
        expect(factobj['values']['clientcert']).to eq('rspec-node.github.net')
        expect(factobj['values']['ipaddress']).to eq('10.20.30.40')
      end
    end

    context 'with fact overrides' do
      it 'should create and populate the fact file' do
        overrides_raw = %w(ipaddress=10.30.50.70 fizz=buzz jsontest=(json){"foo":"bar"})
        overrides = overrides_raw.map { |x| OctocatalogDiff::CatalogDiff::Cli::Helpers::FactOverride.new(x) }
        options = {
          basedir: OctocatalogDiff::Spec.fixture_path('repos/default'),
          fact_file: OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml'),
          fact_override: overrides,
          facts_terminus: 'yaml',
          node: 'rspec-node.github.net'
        }
        logger, _logger_str = OctocatalogDiff::Spec.setup_logger
        testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger)
        fact_file = File.join(testobj.tempdir, 'var/yaml/facts/rspec-node.github.net.yaml')
        expect(File.file?(fact_file)).to eq(true)

        yaml_content = File.read(fact_file).split(/\n/)
        expect(yaml_content[0]).to eq('--- !ruby/object:Puppet::Node::Facts')

        yaml_content[0] = '---' # To avoid need for puppet gem
        factobj = YAML.load(yaml_content.join("\n"))
        expect(factobj).to be_a_kind_of(Hash)
        expect(factobj['name']).to eq('rspec-node.github.net')
        expect(factobj['values']).to be_a_kind_of(Hash)
        expect(factobj['values']['clientcert']).to eq('rspec-node.github.net')
        expect(factobj['values']['ipaddress']).to eq('10.30.50.70')
        expect(factobj['values']['fizz']).to eq('buzz')
        expect(factobj['values']['jsontest']).to eq('foo' => 'bar')
      end
    end

    context 'with invalid options' do
      it 'should raise argument error if called with :facts_terminus defined but not yaml' do
        options = {
          basedir: OctocatalogDiff::Spec.fixture_path('repos/default'),
          facts_terminus: 'chicken',
          fact_file: 'foo'
        }
        logger, _logger_str = OctocatalogDiff::Spec.setup_logger
        r = Regexp.new('Called install_fact_file but :facts_terminus = chicken')
        testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger)
        expect { testobj.send(:install_fact_file, logger, options) }.to raise_error(ArgumentError, r)
      end
    end

    it 'should raise argument error if called with :node undefined' do
      options = {
        basedir: OctocatalogDiff::Spec.fixture_path('repos/default')
      }
      logger, _logger_str = OctocatalogDiff::Spec.setup_logger
      r = Regexp.new('Called install_fact_file without node, or with an empty node')
      expect { OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger) }.to raise_error(ArgumentError, r)
    end

    it 'should raise argument error if no facts are passed' do
      options = {
        basedir: OctocatalogDiff::Spec.fixture_path('repos/default'),
        node: 'foo'
      }
      logger, _logger_str = OctocatalogDiff::Spec.setup_logger
      r = Regexp.new('No facts passed to "install_fact_file" method')
      expect { OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger) }.to raise_error(ArgumentError, r)
    end
  end

  describe '#install_enc' do
    let(:default_options) do
      {
        basedir: OctocatalogDiff::Spec.fixture_path('repos/default'),
        fact_file: OctocatalogDiff::Spec.fixture_path('facts/valid-facts.yaml'),
        facts_terminus: 'yaml',
        node: 'rspec-node.github.net'
      }
    end

    context 'with relative path' do
      it 'should install the ENC at enc.sh' do
        options = default_options.merge(enc: 'config/enc.sh')
        logger, _logger_str = OctocatalogDiff::Spec.setup_logger
        testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger)
        enc = File.join(testobj.tempdir, 'enc.sh')
        expect(File.file?(enc)).to eq(true)
        expect(File.read(enc)).to eq("#!/bin/sh\ncat <<-EOF\n---\n\nEOF\n")
      end
    end

    context 'with relative path including environments/production' do
      it 'should install the ENC at enc.sh' do
        options = default_options.merge(enc: 'environments/production/config/enc.sh')
        logger, _logger_str = OctocatalogDiff::Spec.setup_logger
        testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger)
        enc = File.join(testobj.tempdir, 'enc.sh')
        expect(File.file?(enc)).to eq(true)
        expect(File.read(enc)).to eq("#!/bin/sh\ncat <<-EOF\n---\n\nEOF\n")
      end
    end

    context 'with absolute path' do
      it 'should install the ENC at enc.sh' do
        options = default_options.merge(enc: OctocatalogDiff::Spec.fixture_path('repos/default/config/enc.sh'))
        logger, _logger_str = OctocatalogDiff::Spec.setup_logger
        testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger)
        enc = File.join(testobj.tempdir, 'enc.sh')
        expect(File.file?(enc)).to eq(true)
        expect(File.read(enc)).to eq("#!/bin/sh\ncat <<-EOF\n---\n\nEOF\n")
      end
    end

    context 'as a Puppet Enterprise API call' do
      it 'should install the ENC at enc.sh' do
        content = {
          code: 200,
          parsed: {
            'classes' => { 'foo' => {} },
            'parameters' => {}
          }
        }
        allow(OctocatalogDiff::Util::HTTParty).to receive(:post).and_return(content)

        options = default_options.merge(pe_enc_url: 'https://foo.bar.baz:4433/classifier-api')
        logger, _logger_str = OctocatalogDiff::Spec.setup_logger
        testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(options, logger)
        enc = File.join(testobj.tempdir, 'enc.sh')
        expect(File.file?(enc)).to eq(true)
        expect(File.read(enc)).to eq("#!/bin/sh\ncat <<-EOF\n---\nclasses:\n  foo: {}\nparameters: {}\n\nEOF\n")
      end
    end
  end

  describe '#install_ssl' do
    before(:each) do
      @logger, @logger_str = OctocatalogDiff::Spec.setup_logger
      allow(Socket).to receive(:gethostname).and_return('myhost.mydomain.com')
    end

    let(:default_opts) do
      {
        basedir: OctocatalogDiff::Spec.fixture_path('repos/default'),
        facts_terminus: 'facter'
      }
    end

    let(:ca) { OctocatalogDiff::Spec.fixture_path('ssl/generated/ca.crt') }
    let(:cert) { File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client.crt')) }
    let(:key) { File.read(OctocatalogDiff::Spec.fixture_path('ssl/generated/client.key')) }
    let(:ssl_opts) { { puppetdb_ssl_ca: ca, puppetdb_ssl_client_cert: cert, puppetdb_ssl_client_key: key } }
    let(:password) { 'password' }

    it 'should create directories when SSL setup is provided' do
      opts = default_opts.merge(puppetdb_ssl_ca: ca)
      testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(opts, @logger)
      expect(File.directory?(File.join(testobj.tempdir, 'var', 'ssl', 'certs'))).to eq(true)
      expect(File.directory?(File.join(testobj.tempdir, 'var', 'ssl', 'private'))).to eq(true)
      expect(File.directory?(File.join(testobj.tempdir, 'var', 'ssl', 'private_keys'))).to eq(true)
    end

    it 'should not create directories when SSL setup is not provided' do
      opts = default_opts
      testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(opts, @logger)
      expect(File.directory?(File.join(testobj.tempdir, 'var', 'ssl', 'certs'))).to eq(false)
      expect(File.directory?(File.join(testobj.tempdir, 'var', 'ssl', 'private'))).to eq(false)
      expect(File.directory?(File.join(testobj.tempdir, 'var', 'ssl', 'private_keys'))).to eq(false)
    end

    it 'should error when CA cert is specified but does not exist' do
      opts = default_opts.merge(puppetdb_ssl_ca: 'asldfjasdflkasdfj')
      expect do
        OctocatalogDiff::CatalogUtil::BuildDir.new(opts, @logger)
      end.to raise_error(Errno::ENOENT, /SSL CA file does not exist/)
    end

    it 'should install the CA file in a known place' do
      opts = default_opts.merge(puppetdb_ssl_ca: ca)
      testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(opts, @logger)
      resultfile = File.join(testobj.tempdir, 'var', 'ssl', 'certs', 'ca.pem')
      expect(File.file?(resultfile)).to eq(true)
      expect(File.read(resultfile)).to eq(File.read(ca))
    end

    it 'should install the client certificate in a known place' do
      opts = default_opts.merge(ssl_opts)
      testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(opts, @logger)
      resultfile = File.join(testobj.tempdir, 'var', 'ssl', 'certs', 'myhost.mydomain.com.pem')
      expect(File.file?(resultfile)).to eq(true)
      expect(File.read(resultfile)).to eq(cert)
    end

    it 'should install the client key in a known place' do
      opts = default_opts.merge(ssl_opts)
      testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(opts, @logger)
      resultfile = File.join(testobj.tempdir, 'var', 'ssl', 'private_keys', 'myhost.mydomain.com.pem')
      expect(File.file?(resultfile)).to eq(true)
      expect(File.read(resultfile)).to eq(key)
    end

    it 'should install the client key password in a known place' do
      opts = default_opts.merge(ssl_opts.merge(puppetdb_ssl_client_password: 'password'))
      testobj = OctocatalogDiff::CatalogUtil::BuildDir.new(opts, @logger)
      resultfile = File.join(testobj.tempdir, 'var', 'ssl', 'private', 'password')
      expect(File.file?(resultfile)).to eq(true)
      expect(File.read(resultfile)).to eq('password')
    end

    it 'should error if the client cert is provided with no client key' do
      opts = default_opts.merge(puppetdb_ssl_client_cert: cert, puppetdb_ssl_ca: ca)
      expect do
        OctocatalogDiff::CatalogUtil::BuildDir.new(opts, @logger)
      end.to raise_error(ArgumentError, /--puppetdb-ssl-client-key must be provided/)
    end

    it 'should error if the client key is provided with no client cert' do
      opts = default_opts.merge(puppetdb_ssl_client_key: key, puppetdb_ssl_ca: ca)
      expect do
        OctocatalogDiff::CatalogUtil::BuildDir.new(opts, @logger)
      end.to raise_error(ArgumentError, /--puppetdb-ssl-client-cert must be provided/)
    end

    it 'should error if client cert and key are provided with no CA cert' do
      opts = default_opts.merge(puppetdb_ssl_client_key: key, puppetdb_ssl_client_cert: cert)
      expect do
        OctocatalogDiff::CatalogUtil::BuildDir.new(opts, @logger)
      end.to raise_error(ArgumentError, /--puppetdb-ssl-ca must be provided for client auth/)
    end
  end
end
