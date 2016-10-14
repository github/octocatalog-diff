# Contributing

Hi there! We're thrilled that you'd like to contribute to :octocat:alog-diff. Your help is essential for keeping it great.

Please note that this project adheres to the [Open Code of Conduct](http://todogroup.org/opencodeofconduct/#GitHub%20Octocatalog-Diff/opensource@github.com). By participating in this project you agree to abide by its terms.

We strongly recommend that you check out the [roadmap](/doc/roadmap.md) before getting started. If you have questions, or you'd like to check with us before embarking on a major development effort, please [open an issue](https://github.com/github/octocatalog-diff/issues/new).

## How to contribute

This project uses the [GitHub Flow](https://guides.github.com/introduction/flow/). That means that the `master` branch is stable and new development is done in feature branches. Feature branches are merged into the `master` branch via a Pull Request.

0. Fork and clone the repository
0. Configure and install the dependencies: `script/bootstrap`
0. Make sure the tests pass on your machine: `rake`
0. Create a new branch: `git checkout -b my-branch-name`
0. Make your change, add tests, and make sure the tests still pass
0. Push to your fork and submit a pull request
0. Pat yourself on the back and wait for your pull request to be reviewed and merged

We will handle updating the version, tagging the release, and releasing the gem. Please don't bump the version or otherwise attempt to take on these administrative internal tasks as part of your pull request.

Here are a few things you can do that will increase the likelihood of your pull request being accepted:

- Make sure your contribution is consistent with our [roadmap](roadmap.md).

- Follow the [style guide](https://github.com/bbatsov/ruby-style-guide).

  - We support Ruby 2.0 and higher. This means, for example, that you can use the 2.0 hash syntax (e.g. `options = { font_size: 10, font_family: 'Arial' }`, but **not** the 2.1 keyword arguments for methods (e.g., `def foo(bar: 'baz')`).

  - We use single quotes (`'`) rather than double quotes (`"`) for strings with no interpolation.

  - We use [rubocop](http://batsov.com/rubocop/) to enforce style, because we strive for efficient code reviews. You can view our [.rubocop.yml rules file](/.rubocop.yml) or use `script/fmt` in your checkout to run Rubocop with our rule set. If you use our bootstrap script when cloning your repo, you will have installed Rubocop as a pre-commit hook in the repository.

- Write unit tests. Each changed or added method should be covered by [unit tests](/spec/octocatalog-diff/tests). You can create a [coverage report](/doc/dev/coverage.md) via our rake task if you wish. We'd like to maintain 100% on unit test coverage (`rake coverage:spec`). You can use simplecov comments (`# :nocov:`) to wrap portions of code that it is impractical or not worthwhile to test.

- Write an integration test. For any new features, e.g. when you have added a new command line flag, please consider adding an [integration test](/spec/octocatalog-diff/integration). You can check integration test coverage with `rake coverage:integration`. We do not demand 100% coverage here, as it is impractical to test all possible error conditions. However, it would be great if the important parts of your code are exercised in the integration tests.

- Write or update documentation. If you have added a feature or changed an existing one, please make appropriate changes to the docs. Please note that the [options reference](/doc/optionsref.md) is automatically generated, so you do not need to update that file. (Or, you can run `rake doc:build` to rebuild it.)

- Keep your change as focused as possible. If there are multiple changes you would like to make that are not dependent upon each other, consider submitting them as separate pull requests.

- We target `octocatalog-diff` to support Puppet 3.8.7 and 4.5 (and subsequent releases). There were some changes to the catalog format between these versions. We have abstracted these differences with methods such as `resources` in the [catalog object](/lib/octocatalog-diff/catalog.rb), but if you are directly interacting with the JSON of the catalog, be careful of this. Our CI job will test with both Puppet 3 and Puppet 4, so writing complete tests are a good way of ensuring that your code is compatible.

- Write a [good commit message](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).

## License note

We can only accept contributions that are compatible with the MIT license.

It's OK to depend on gems licensed under either Apache 2.0 or MIT, but we cannot add dependencies on any gems that are licensed under GPL.

Any contributions you make must be under the MIT license.

## Resources

- [Contributing to Open Source on GitHub](https://guides.github.com/activities/contributing-to-open-source/)
- [Using Pull Requests](https://help.github.com/articles/using-pull-requests/)
- [GitHub Help](https://help.github.com)
