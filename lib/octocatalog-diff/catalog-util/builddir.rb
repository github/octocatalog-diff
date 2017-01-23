# frozen_string_literal: true

require 'yaml'

require_relative '../facts'
require_relative 'enc'

module OctocatalogDiff
  module CatalogUtil
    # Represents a directory that is created such that a catalog can be compiled
    # in it. This has the following major functions:
    # - Create the temporary directory that will serve as the puppet configuration directory
    # - Register a handler to remove the temporary directory upon exit
    # - Install needed configuration files within the directory (e.g. puppetdb.conf)
    # - Install the facts into the directory
    # - Install 'environments/(environment)' which is a symlink to the checkout of the puppet code
    class BuildDir
      # Allow the path to the temporary directory to be read
      attr_reader :tempdir, :enc, :fact_file

      # Constructor
      # Options for constructor:
      # :puppetdb_url [String] PuppetDB Server URLs
      # :puppetdb_server_url_timeout [Fixnum] Timeout (seconds) for puppetdb.conf
      # :facts [OctocatalogDiff::Facts] Facts object
      # :fact_file [String] File from which to read facts
      # :node [String] Node name
      # :basedir [String] Directory containing puppet code
      # :enc [String] ENC script file (can be relative or absolute path)
      # :pe_enc_url [String] ENC URL (for Puppet Enterprise node classification service)
      # :hiera_config [String] hiera configuration file (relative to base directory)
      # :hiera_path [String] relative path to hiera data files (mutually exclusive with :hiera_path_strip)
      # :hiera_path_strip [String] string to strip off the beginning of :datadir
      # :puppetdb_ssl_ca [String] Path to SSL CA certificate
      # :puppetdb_ssl_client_key [String] String representation of SSL client key
      # :puppetdb_ssl_client_cert [String] String representation of SSL client certificate
      # :puppetdb_ssl_client_password [String] Password to unlock SSL private key
      # @param options [Hash] Options for class; see above description
      def initialize(options = {}, logger = nil)
        @options = options.dup
        @tempdir = Dir.mktmpdir
        at_exit { FileUtils.rm_rf(@tempdir) if File.directory?(@tempdir) }

        @factdir = nil
        @enc = nil
        @fact_file = nil
        @node = options[:node]
        @facts_terminus = options.fetch(:facts_terminus, 'yaml')

        create_structure
        create_symlinks(logger)

        # These configurations are optional. Don't call the methods if parameters are nil.
        unless options[:puppetdb_url].nil?
          install_puppetdb_conf(logger, options[:puppetdb_url], options[:puppetdb_server_url_timeout])
          install_routes_yaml(logger)
        end
        install_hiera_config(logger, options) unless options[:hiera_config].nil?

        @fact_file = install_fact_file(logger, options) if @facts_terminus == 'yaml'
        @enc = install_enc(logger) unless options[:enc].nil? && options[:pe_enc_url].nil?
        install_ssl(logger, options) if options[:puppetdb_ssl_ca] || options[:puppetdb_ssl_client_cert]
      end

      # Create common structure
      def create_structure
        %w(facts var var/ssl var/yaml var/yaml/facts).each do |dir|
          Dir.mkdir(File.join(@tempdir, dir))
          FileUtils.chmod 0o755, File.join(@tempdir, dir)
        end
      end

      # Create symlinks.
      #
      # If the `--preserve-environments` option is used, the `environments` directory, plus `modules` and
      # `manifests` symlinks are created. Otherwise, `environments/production` is pointed at the base
      # directory.
      #
      # @param logger [Logger] Logger object
      def create_symlinks(logger = nil)
        if @options[:preserve_environments]
          install_directory_symlink(logger, File.join(@options[:basedir], 'environments'), 'environments')
          @options.fetch(:create_symlinks, %w(modules manifests)).each do |x|
            install_directory_symlink(logger, File.join(@options[:basedir], x), x)
          end
        else
          if @options[:environment]
            logger.warn '--environment is ignored unless --preserve-environments is used' unless logger.nil?
          end
          if @options[:create_symlinks]
            logger.warn '--create-symlinks is ignored unless --preserve-environments is used' unless logger.nil?
          end
          install_directory_symlink(logger, @options[:basedir])
        end
      end

      # Install puppetdb.conf file in temporary directory
      # @param server_urls [String] String for server_urls in puppetdb.conf
      # @param server_url_timeout [Fixnum] Value for server_url_timeout in puppetdb.conf
      def install_puppetdb_conf(logger, server_urls, server_url_timeout = 30)
        unless server_urls.is_a?(String)
          raise ArgumentError, "server_urls must be a string, got a: #{server_urls.class}"
        end

        server_url_timeout ||= 30 # If called with nil argument, supply default
        unless server_url_timeout.is_a?(Fixnum)
          raise ArgumentError, "server_url_timeout must be a fixnum, got a: #{server_url_timeout.class}"
        end

        puppetdb_conf = File.join(@tempdir, 'puppetdb.conf')
        File.open(puppetdb_conf, 'w') do |f|
          f.write "[main]\n"
          f.write "server_urls = #{server_urls}\n"
          f.write "server_url_timeout = #{server_url_timeout}\n"
        end
        logger.debug("Installed puppetdb.conf file at #{puppetdb_conf}")
      end

      # Install routes.yaml file in temporary directory
      # No parameters or return - thus just writes a file (and notes it to debugging log)
      # Note: catalog cache => json avoids sending the compiled catalog to PuppetDB
      # even if storeconfigs is enabled.
      def install_routes_yaml(logger)
        routes_yaml = File.join(@tempdir, 'routes.yaml')
        routes_hash = {
          'master' => {
            'facts' => {
              'terminus' => @facts_terminus,
              'cache' => 'yaml'
            },
            'catalog' => {
              'cache' => 'json'
            }
          }
        }
        File.open(routes_yaml, 'w') { |f| f.write(routes_hash.to_yaml) }
        logger.debug("Installed routes.yaml file at #{routes_yaml}")
      end

      # Install the fact file in temporary directory
      # @param options [Hash] Options
      def install_fact_file(logger, options)
        unless @facts_terminus == 'yaml'
          raise ArgumentError, "Called install_fact_file but :facts_terminus = #{@facts_terminus}"
        end
        unless options[:node].is_a?(String) && !options[:node].empty?
          raise ArgumentError, 'Called install_fact_file without node, or with an empty node'
        end

        facts = if options[:fact_file]
          raise Errno::ENOENT, "Fact file #{options[:fact_file]} does not exist" unless File.file?(options[:fact_file])
          fact_file_opts = { fact_file_string: File.read(options[:fact_file]) }
          fact_file_opts[:backend] = Regexp.last_match(1).to_sym if options[:fact_file] =~ /.*\.(\w+)$/
          OctocatalogDiff::Facts.new(fact_file_opts)
        elsif options[:facts].is_a?(OctocatalogDiff::Facts)
          options[:facts].dup
        else
          raise ArgumentError, 'No facts passed to "install_fact_file" method'
        end

        if options[:fact_override].is_a?(Array)
          options[:fact_override].each do |override|
            old_value = facts.fact(override.key)
            facts.override(override.key, override.value)
            logger.debug("Override #{override.key} from #{old_value.inspect} to #{override.value.inspect}")
          end
        end

        fact_file_out = File.join(@tempdir, 'var', 'yaml', 'facts', "#{options[:node]}.yaml")
        File.open(fact_file_out, 'w') { |f| f.write(facts.facts_to_yaml(options[:node])) }
        logger.debug("Installed fact file at #{fact_file_out}")
        fact_file_out
      end

      # Install symbolic link to puppet environment
      # @param dir [String] Directory to link to
      # @param target [String] Where the symlink is created, relative to tempdir
      def install_directory_symlink(logger, dir, target = 'environments/production')
        raise ArgumentError, "Called install_directory_symlink with #{dir.class} argument" unless dir.is_a?(String)
        raise Errno::ENOENT, "Specified directory #{dir} doesn't exist" unless File.directory?(dir)
        symlink_target = File.join(@tempdir, target)

        if target =~ %r{/}
          parent_dir = File.dirname(symlink_target)
          FileUtils.mkdir_p parent_dir
        end

        FileUtils.rm_f symlink_target if File.exist?(symlink_target)
        FileUtils.symlink dir, symlink_target
        logger.debug("Symlinked #{symlink_target} -> #{dir}")
      end

      # Install ENC
      # @param enc [String] Path to ENC script, relative to checkout
      def install_enc(logger)
        raise ArgumentError, 'A node must be specified when using an ENC' unless @node.is_a?(String)
        enc_obj = OctocatalogDiff::CatalogUtil::ENC.new(@options.merge(tempdir: @tempdir))
        enc_obj.execute(logger)
        raise "Failed ENC: #{enc_obj.error_message}" if enc_obj.error_message

        enc_path = File.join(@tempdir, 'enc.sh')
        File.open(enc_path, 'w') do |f|
          f.write "#!/bin/sh\n"
          f.write "cat <<-EOF\n"
          f.write enc_obj.content
          f.write "\nEOF\n"
        end
        FileUtils.chmod 0o755, enc_path

        logger.debug("Installed ENC to echo content, #{enc_obj.content.length} bytes")
        enc_path
      end

      # Install hiera config file
      # @param options [Hash] Options hash
      def install_hiera_config(logger, options)
        # Validate hiera config file
        hiera_config = options[:hiera_config]
        unless hiera_config.is_a?(String)
          raise ArgumentError, "Called install_hiera_config with a #{hiera_config.class} argument"
        end
        file_src = if hiera_config.start_with? '/'
          hiera_config
        elsif hiera_config =~ %r{^environments/#{Regexp.escape(environment)}/}
          File.join(@tempdir, hiera_config)
        else
          File.join(@tempdir, 'environments', environment, hiera_config)
        end
        raise Errno::ENOENT, "hiera.yaml (#{file_src}) wasn't found" unless File.file?(file_src)

        # Munge datadir in hiera config file
        obj = YAML.load_file(file_src)
        (obj[:backends] || %w(yaml json)).each do |key|
          next unless obj.key?(key.to_sym)
          if options[:hiera_path_strip].is_a?(String)
            next if obj[key.to_sym][:datadir].nil?
            rexp1 = Regexp.new('^' + options[:hiera_path_strip])
            obj[key.to_sym][:datadir].sub!(rexp1, @tempdir)
          elsif options[:hiera_path].is_a?(String)
            obj[key.to_sym][:datadir] = File.join(@tempdir, 'environments', environment, options[:hiera_path])
          end
          rexp2 = Regexp.new('%{(::)?environment}')
          obj[key.to_sym][:datadir].sub!(rexp2, environment)

          # Make sure the dirctory exists. If not, log a warning. This is *probably* a setup error, but we don't
          # want it to be fatal in case (for example) someone is doing an octocatalog-diff to verify moving this
          # directory around or even setting up Hiera for the very first time.
          unless File.directory?(obj[key.to_sym][:datadir])
            message = "WARNING: Hiera datadir for #{key} doesn't seem to exist at #{obj[key.to_sym][:datadir]}"
            logger.warn message
          end
        end

        # Write properly formatted hiera config file into temporary directory
        File.open(File.join(@tempdir, 'hiera.yaml'), 'w') { |f| f.write(obj.to_yaml.gsub('!ruby/sym ', ':')) }
        logger.debug("Installed hiera.yaml from #{file_src} to #{File.join(@tempdir, 'hiera.yaml')}")
      end

      # Install SSL certificate authority certificate, client key, and client certificate into the
      # expected locations within Puppet's SSL directory. Note that if the client key has a password,
      # this will write the key (without password) onto disk, because Puppet doesn't support unlocking
      # the private key.
      # @param logger [Logger] Logger object
      # @param options [Hash] Options hash
      def install_ssl(logger, options)
        return unless options[:puppetdb_ssl_client_cert] || options[:puppetdb_ssl_client_key] || options[:puppetdb_ssl_ca]

        # Create directory structure expected by Puppet
        %w(var/ssl/certs var/ssl/private var/ssl/private_keys).each do |dir|
          Dir.mkdir(File.join(@tempdir, dir))
          FileUtils.chmod 0o700, File.join(@tempdir, dir)
        end

        # SSL client auth requested?
        if options[:puppetdb_ssl_client_cert] || options[:puppetdb_ssl_client_key]
          raise ArgumentError, '--puppetdb-ssl-ca must be provided for client auth' unless options[:puppetdb_ssl_ca]
          raise ArgumentError, '--puppetdb-ssl-client-cert must be provided' unless options[:puppetdb_ssl_client_cert]
          raise ArgumentError, '--puppetdb-ssl-client-key must be provided' unless options[:puppetdb_ssl_client_key]
          install_ssl_client(logger, options)
        end

        # SSL CA provided?
        install_ssl_ca(logger, options) if options[:puppetdb_ssl_ca]
      end

      private

      # Install SSL certificate authority certificate
      # @param logger [Logger] Logger object
      # @param options [Hash] Options hash
      def install_ssl_ca(logger, options)
        ca_file = options[:puppetdb_ssl_ca]
        raise Errno::ENOENT, 'SSL CA file does not exist' unless File.file?(ca_file)
        ca_content = File.read(ca_file)
        ca_outfile = File.join(@tempdir, 'var', 'ssl', 'certs', 'ca.pem')
        File.open(ca_outfile, 'w') { |f| f.write(ca_content) }
        logger.debug "Installed CA certificate in #{ca_outfile}"
      end

      # Install SSL keypair for client certificate authentication
      # @param logger [Logger] Logger object
      # @param options [Hash] Options hash
      def install_ssl_client(logger, options)
        # Since Puppet always looks for the key and cert in a file named after the hostname, determine the
        # hostname here for the purposes of naming the files.
        require 'socket'
        host = Socket.gethostname
        install_ssl_client_cert(logger, host, options[:puppetdb_ssl_client_cert])
        install_ssl_client_key(logger, host, options[:puppetdb_ssl_client_key])
        install_ssl_client_password(logger, options[:puppetdb_ssl_client_password])
      end

      def install_ssl_client_cert(logger, host, content)
        cert_outfile = File.join(@tempdir, 'var', 'ssl', 'certs', "#{host}.pem")
        File.open(cert_outfile, 'w') { |f| f.write(content) }
        logger.debug "Installed SSL client certificate in #{cert_outfile}"
      end

      def install_ssl_client_key(logger, host, content)
        key_outfile = File.join(@tempdir, 'var', 'ssl', 'private_keys', "#{host}.pem")
        File.open(key_outfile, 'w') { |f| f.write(content) }
        logger.debug "Installed SSL client key in #{key_outfile}"
      end

      def install_ssl_client_password(logger, password)
        return unless password
        password_outfile = File.join(@tempdir, 'var', 'ssl', 'private', 'password')
        File.open(password_outfile, 'w') { |f| f.write(password) }
        logger.debug "Installed SSL client key password in #{password_outfile}"
      end

      def environment
        @options[:preserve_environments] ? @options.fetch(:environment, 'production') : 'production'
      end
    end
  end
end
