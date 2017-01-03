# These are all the classes we believe people might want to call directly, so load
# them in response to a 'require octocatalog-diff'.

loads = [
  'api',
  'bootstrap',
  'catalog',
  'facts',
  'puppetdb',
  'version',
  'catalog-diff/cli'
]
loads.each { |f| require_relative "octocatalog-diff/#{f}" }
