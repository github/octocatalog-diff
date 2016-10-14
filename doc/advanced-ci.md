# Using `octocatalog-diff` in CI

## Catalog compilation check

Compile the catalog for several important hosts, and ensure that all catalogs successfully compile before permitting the merge. This is a pass/fail check.

- [Sample rspec file for catalog compilation test](/examples/ci/puppet_catalogs_spec.rb)

## Catalog difference analysis

Compute the difference between the proposed code and the base branch across a number of hosts. This is more than just a pass/fail check, as a human should review the results to ensure that the differences are expected.

- [Sample rspec file for catalog difference analysis](/examples/ci/puppet_catalog_diff_spec.rb)
