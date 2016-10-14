<!--
Hi there! We are delighted that you have chosen to contribute to octocatalog-diff.

If you have not already done so, please read our Contributing document, found here: https://github.com/github/octocatalog-diff/blob/master/.github/CONTRIBUTING.md

Please remember that all activity in this project, including pull requests, needs to comply with the Open Code of Conduct, found here: http://todogroup.org/opencodeofconduct/

Any contributions to this project must be made under the MIT license.

You do NOT need to bump the version number or regenerate the "Command line options reference" page. We will do this for you at or after the time we merge your contribution.
-->

## Overview

This pull request [introduces/changes/removes] [functionality/feature].

(Please write a summary of your pull request here. This paragraph should go into detail about what is changing, the motivation behind this change, and the approach you took.)

## Checklist

- [ ] Make sure that all of the tests pass, and fix any that don't. Just run `rake` in your checkout directory, or review the CI job triggered whenever you push to a pull request.
- [ ] Make sure that there is 100% [test coverage](https://github.com/github/octocatalog-diff/blob/master/doc/dev/coverage.md) by running `rake coverage:spec` or ignoring untestable sections of code with `# :nocov` comments. If you need help getting to 100% coverage please ask; however, don't just submit code with no tests.
- [ ] If you have added a new command line option, we would greatly appreciate a corresponding [integration test](https://github.com/github/octocatalog-diff/blob/master/doc/dev/integration-tests.md) that exercises it from start to finish. This is optional but recommended.
- [ ] If you have added any new gem dependencies, make sure those gems are licensed under the MIT or Apache 2.0 license. We cannot add any dependencies on gems licensed under GPL.
- [ ] If you have added any new gem dependencies, make sure you've checked in a copy of the `.gem` file into the [vendor/cache](https://github.com/github/octocatalog-diff/tree/master/vendor/cache) directory.

/cc [related issues] [teams and individuals, making sure to mention why you're CC-ing them]
