# Integration tests

Integration tests are designed to run `octocatalog-diff` from beginning to end with options and fixtures to demonstrate a desired behavior.

The integration tests are found in [`/spec/octocatalog-diff/integration`](/spec/octocatalog-diff/integration).

## Writing an integration test

We recommend using the provided [`integration_helper.rb`](/spec/octocatalog-diff/integration/integration_helper.rb) which provides some handy functions to reduce duplicative code, and hopefully make integration tests easier to write.

An integration test that compiles one or two catalogs from a repository will look like this:

```ruby
describe 'whatever behavior' do
  before(:all) do
    @result = OctocatalogDiff::Integration.integration(
      spec_repo: 'fact-overrides', # The repository directory in /spec/octocatalog-diff/fixtures/repos
      spec_fact_file: 'valid-facts.yaml', # The fact file in /spec/octocatalog-diff/fixtures/facts
      argv: '--debug --from-fact-override somekey=somevalue', # Command line arguments
    )
    # At this point @result is a hash containing these keys:
    # @result[:logs] is a String containing everything printed to STDERR (Logger)
    # @result[:output] is a String containing everything printed to STDOUT
    # @result[:diffs] is an Array of differences
    # @result[:exitcode] is an Integer representing the exit code: 0 = no changes, 1 = failure, 2 = success, with changes
    # @result[:exception] contains any exception that was thrown
  end

  it 'should do whatever' do
    # ...
  end
end
```

An integration test that uses already-compiled catalogs from the fixtures directory will look like this:

```ruby
describe 'whatever behavior' do
  before(:all) do
    @result = OctocatalogDiff::Integration.integration(
      spec_catalog_old: 'catalog-1.json', # The repository directory in /spec/octocatalog-diff/fixtures/catalogs
      spec_catalog_new: 'catalog-2.json', # The repository directory in /spec/octocatalog-diff/fixtures/catalogs
      argv: '--debug --display-format :color', # Command line arguments
    )
    # At this point @result is a hash containing these keys:
    # @result[:logs] is a String containing everything printed to STDERR (Logger)
    # @result[:output] is a String containing everything printed to STDOUT
    # @result[:diffs] is an Array of differences
    # @result[:exitcode] is an Integer representing the exit code: 0 = no changes, 1 = failure, 2 = success, with changes
    # @result[:exception] contains any exception that was thrown
  end

  it 'should do whatever' do
    # ...
  end
end
```

## Hints for writing an integration test

0. If your integration test deals only with the calculation or display of differences, and not catalog compilation, and you are compiling catalogs multiple times, prefer `spec_catalog_old` and `spec_catalog_new` to pass in pre-compiled catalogs. This will make the test run faster.

0. It's a good idea to check the exit code in a test of its own, and then `pending` any subsequent tests if that exit code doesn't match. This way only one test, and not all the tests, will fail if the catalog compilation doesn't work.
