# Test coverage

We provide two types of tests for octocatalog-diff:

  - Unit tests (found in [/spec/octocatalog-diff/tests](/spec/octocatalog-diff/tests))
  - Integration tests (found in [/spec/octocatalog-diff/integration](/spec/octocatalog-diff/integration))

The difference between these is as follows. Unit tests are designed to test the smallest bit of code that's practical to test. Integration tests are designed to run from end-to-end, starting via the invocation from the command line, exercising internals, and checking output from the end result.

It's our goal to have as much test coverage as we can provide from both sides, so that we can have confidence in anything we release.

## Coverage report

The `simplecov` gem is bundled with octocatalog-diff to produce coverage reports.

To build a coverage report for unit tests only:

  ```
  rake coverage:spec
  ```

To build a coverage report for integration tests only:

  ```
  rake coverage:integration
  ```

To build a coverage report combining the results of unit tests and integration test:

  ```
  rake coverage:all
  ```

Running any of these tests creates a `coverage` directory in the root of the project, and this contains an `index.html` file with a graphical report. Open this file in a browser to see the results.
