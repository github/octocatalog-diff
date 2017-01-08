# These are all the classes we believe people might want to call directly, so load
# them in response to a 'require octocatalog-diff'.

loads = %w(api/v1 bootstrap catalog cli errors facts puppetdb version)
loads.each { |f| require_relative "octocatalog-diff/#{f}" }
