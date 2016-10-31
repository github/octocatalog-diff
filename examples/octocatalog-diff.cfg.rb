# This is a configuration file for octocatalog-diff (https://github.com/github/octocatalog-diff).
#
# When octocatalog-diff runs, it will look for configuration files in the following locations:
# - As specified by the environment variable OCTOCATALOG_DIFF_CONFIG_FILE
# - Your current working directory: `$PWD/.octocatalog-diff.cfg.rb`
# - Your home directory: `$HOME/.octocatalog-diff.cfg.rb`
# - The Puppet configuration directory: `/opt/puppetlabs/octocatalog-diff/octocatalog-diff.cfg.rb`
# - The local system directory: `/usr/local/etc/octocatalog-diff.cfg.rb`
# - The system directory: `/etc/octocatalog-diff.cfg.rb`
#
# It will use the first configuration file it finds in the above locations. If it does not find any
# configuration files, a default configuration will be used.
#
# To test this configuration file, place it in one of the above locations and run:
#   octocatalog-diff --config-test

module OctocatalogDiff
  # Configuration class. See comments for each method to define the most common parameters.
  class Config
    ################################################################################################
    # Configure your settings in this method!
    # This method (self.config) must exist, and must return a hash.
    ################################################################################################

    def self.config
      settings = {}

      ##############################################################################################
      # hiera_yaml_file
      #   Path to the hiera.yaml configuration file. If the path starts with a `/`, then it is
      #   treated as an absolute path on this system. Otherwise, the path will be treated as
      #   a relative path. If you don't specify this, the tool will assume you aren't using Hiera.
      #   More: https://github.com/github/octocatalog-diff/blob/master/doc/configuration-hiera.md
      ##############################################################################################

      # settings[:hiera_yaml_file] = '/etc/puppetlabs/puppet/hiera.yaml' # Absolute path
      # settings[:hiera_yaml_file] = 'environments/production/config/hiera.yaml' # Relative path

      ##############################################################################################
      # hiera_path_strip
      #   Portion of the `:datadir:` to strip (used for JSON and YAML data sources). For
      #   example, perhaps your hiera.yaml file contains this code:
      #     :yaml:
      #       :datadir: /var/lib/puppet/environments/%{::environment}/hieradata
      #   In this case, you desire to strip `/var/lib/puppet` from the beginning of the path,
      #   in order that octocatalog-diff can find your hiera datafiles in the compilation
      #   location, which is {temporary directory}/environments/production/hieradata.
      #   More: https://github.com/github/octocatalog-diff/blob/master/doc/configuration-hiera.md
      ##############################################################################################

      # settings[:hiera_path_strip] = '/var/lib/puppet'

      ##############################################################################################
      # puppetdb_url
      #   URL, including protocol and port number, to your PuppetDB instance. This is used for
      #   octocatalog-diff to connect and retrieve facts (and possibly compiled catalogs).
      #   Example: https://puppetdb.yourcompany.com:8081
      #   More: https://github.com/github/octocatalog-diff/blob/master/doc/configuration-puppetdb.md
      ##############################################################################################

      # settings[:puppetdb_url] = 'https://puppetdb.yourcompany.com:8081'

      ##############################################################################################
      # puppetdb_ssl_ca
      #   CA certificate (public cert) that signed the PuppetDB certificate. Provide this if you
      #   want octocatalog-diff to verify the PuppetDB certificate when it connects. You should be
      #   doing this. You can specify an absolute path starting with `/`, or a relative path.
      #   If you don't specify this, SSL will still work, but the tool won't verify the certificate
      #   of the puppetdb server it's connecting to.
      #   More: https://github.com/github/octocatalog-diff/blob/master/doc/configuration-puppetdb.md
      ##############################################################################################

      # settings[:puppetdb_ssl_ca] = '/etc/puppetlabs/puppet/ssl/certs/ca.pem'

      ##############################################################################################
      # puppetdb_ssl_client_key
      # puppetdb_ssl_client_password
      # puppetdb_ssl_client_cert
      # puppetdb_ssl_client_pem
      #
      #   This sets up SSL authentication for PuppetDB.
      #
      #   For SSL authentication, the key and certificate used for SSL client authentication.
      #   Don't set these if your PuppetDB is unauthenticated. The provided example may work if you
      #   run octocatalog-diff on a machine managed by Puppet, and your PuppetDB authenticates
      #   clients with that same CA. Otherwise, fill in the actual path to the key and the
      #   certificate in the relevant settings. If the key is password protected, set
      #   :puppetdb_ssl_client_password to the text of the password.
      #
      #   You can configure this in one of two ways:
      #     1. Set `puppetdb_ssl_client_key` and `puppetdb_ssl_client_cert` individually.
      #     2. Set `puppetdb_ssl_client_pem` to the concatenation of the key and the certificate.
      #
      #   VERY IMPORTANT: settings[:puppetdb_ssl_client_key], settings[:puppetdb_ssl_client_cert], and
      #     settings[:puppetdb_ssl_client_pem] need to be set to the TEXT OF THE CERTIFICATE/KEY, not
      #     just the file name of the certificate. You'll probably need to use something like this:
      #        settings[:puppetdb_ssl_client_WHATEVER] = File.read("...")
      #
      #   More: https://github.com/github/octocatalog-diff/blob/master/doc/configuration-puppetdb.md
      ##############################################################################################

      # require 'socket'
      # fqdn = Socket.gethostbyname(Socket.gethostname).first
      # settings[:puppetdb_ssl_client_key] = File.read("/etc/puppetlabs/puppet/ssl/private_keys/#{fqdn}.pem")
      # settings[:puppetdb_ssl_client_cert] = File.read("/etc/puppetlabs/puppet/ssl/certs/#{fqdn}.pem")

      # For keys generated by Puppet, passwords are not needed so the next setting can be left commented.
      # If you generated your own key outside of Puppet and it has a password, specify it here.
      # settings[:puppetdb_ssl_client_password] = 'your-password-here'

      ##############################################################################################
      # enc
      #   Path to the external node classifier. If the path starts with a `/`, then it is
      #   treated as an absolute path on this system. Otherwise, the path will be treated as
      #   a relative path. If you don't specify this, the tool will assume you aren't using an ENC.
      #   More: https://github.com/github/octocatalog-diff/blob/master/doc/configuration-enc.md
      ##############################################################################################

      # settings[:enc] = '/etc/puppetlabs/puppet/enc.sh' # Absolute path
      # settings[:enc] = 'environments/production/config/enc.sh' # Relative path

      ##############################################################################################
      # storeconfigs
      #   If you are using exported/collected resources from PuppetDB, you must enable the
      #   `storeconfigs` option. If you are not using exported/collected resources, then you
      #   need not enable this option. If you aren't sure if you're using storeconfigs or not,
      #   then type this on your Puppet master to find out:
      #     puppet config --section master print storeconfigs
      ##############################################################################################

      settings[:storeconfigs] = false

      ##############################################################################################
      # bootstrap_script
      #   When you check out your Puppet repository, do you need to run a script to prepare that
      #   repository for use? For example, maybe you need to run librarian-puppet to install
      #   modules. octocatalog-diff allows you to specify a script that will be run within the
      #   checked-out branch. If the path starts with a `/`, then it is treated as an absolute
      #   path on this system. Otherwise, the path will be treated as a relative path. If you don't
      #   specify this, the tool will assume you don't need a bootstrap script.
      ##############################################################################################

      # settings[:bootstrap_script] = '/etc/puppetlabs/repo-bootstrap.sh' # Absolute path
      # settings[:bootstrap_script] = 'script/bootstrap' # Relative path

      ##############################################################################################
      # pass_env_vars
      #   When a catalog is compiled, the compilation occurs in a clean environment. If you have
      #   environment variables that need to be passed through, e.g. with authentication tokens,
      #   specify them here. The return value must be an array.
      ##############################################################################################

      # settings[:pass_env_vars] = %w(AUTH_USERNAME AUTH_TOKEN)

      ##############################################################################################
      # puppet_binary
      #   This is the full path to the puppet binary on your system. If you don't specify this,
      #   the tool will just run 'puppet' and hope to find it in your path.
      ##############################################################################################

      # settings[:puppet_binary] = '/usr/bin/puppet'
      # settings[:puppet_binary] = '/opt/puppetlabs/puppet/bin/puppet'

      ##############################################################################################
      # from_env
      #   When working with branches, this is the default "from" environment to use. This should
      #   be set to the branch that is considered "stable" in your workflow. If you are using the
      #   GitHub flow, this is probably 'origin/master'.
      ##############################################################################################

      settings[:from_env] = 'origin/master'

      ##############################################################################################
      # Less commonly changed settings
      ##############################################################################################

      # Header: options are :default, or can optionally be set to a custom string you provide.
      # The default header is like: 'diff NODE_NAME/branch-old NODE_NAME/branch-new'.
      settings[:header] = :default

      # Cache the master branch and catalogs in home directory. This will speed up the second
      # and subsequent octocatalog-diff runs against the same node on the same branch. It's safe
      # to leave this enabled, but if you know that you never want to do caching on your system,
      # comment these lines out so the tool doesn't spend the time maintaining the cache.
      settings[:cached_master_dir] = File.join(ENV['HOME'], '.octocatalog-diff-cache')
      settings[:safe_to_delete_cached_master_dir] = settings[:cached_master_dir]

      # This is the base directory of your Puppet checkout. Generally you are `cd` into the
      # directory when you run octocatalog-diff so this default will just work. However you
      # can hard-code this or get it from the environment if you need to.
      settings[:basedir] = Dir.pwd
      # settings[:basedir] = ENV['WORKSPACE'] # May work with Jenkins

      # This method must return the 'settings' hash.
      settings
    end
  end
end
