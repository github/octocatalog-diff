# These are all the classes we believe people might want to call directly, so load
# them in response to a 'require octocatalog-diff'.

loads = %w(bootstrap catalog cli facts puppetdb version)
loads.each { |f| require_relative "octocatalog-diff/#{f}" }
