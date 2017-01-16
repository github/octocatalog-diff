# How to add new command line options

This document contains a checklist and guidance to adding new command line options.

## Checklist

Please copy and paste this text into your Pull Request. This will create boxes for each step along the way, which you can then check off when complete.

```
- [ ] REQUIRED: Add new file in `lib/octocatalog-diff/cli/options`
- [ ] REQUIRED: Add corresponding test in `spec/octocatalog-diff/tests/cli/options`
- [ ] OPTIONAL: Add default value in `lib/octocatalog-diff/cli.rb`
- [ ] OPTIONAL: Add configuration example in `examples/octocatalog-diff.cfg.rb`
- [ ] REQUIRED: Add code to implement your option in `lib`
- [ ] REQUIRED: Add corresponding tests for code to implement your option in `spec/octocatalog-diff/tests`
- [ ] OPTIONAL: Add an integration test to test your option in `spec/octocatalog-diff/integration`
```

## Procedure

### Create option parser

Option parsers are created in [`lib/octocatalog-diff/cli/options`](/lib/octocatalog-diff/cli/options).

Your option should have a "long form" that contains dashes and not underscores. For example, you should prefer `--your-new-option` and NOT use `--your_new_option`.

The file you create should reflect the name of your option. Generally the file name is the command line flag, with `-` converted to `_`.

The key that your option creates in the options hash should generally be a symbol, named the same as the command line flag, with `-` converted to `_`. In this example, `:your_new_option`.

If you are creating a binary (yes-no) option, please recognize both `--your-new-option` and `--no-your-new-option`.

We recommend copying prior art as a template:

- For a binary (yes-no) option, look at [`quiet.rb`](/lib/octocatalog-diff/cli/options/quiet.rb).

- For an option that takes an integer parameter, look at [`retry_failed_catalog.rb`](/lib/octocatalog-diff/cli/options/retry_failed_catalog.rb).

- For an option that takes an string parameter, look at [`bootstrap_script.rb`](/lib/octocatalog-diff/cli/options/bootstrap_script.rb).

- For an option that takes an array or can be specified more than once, look at [`bootstrap_environment.rb`](/lib/octocatalog-diff/cli/options/bootstrap_environment.rb).

If you can do simple validation of the argument, such as making sure the argument (if specified) matches a particular regular expression or is one of a particular set of values, please do that within the option file. For example, look at [`facts_terminus.rb`](/lib/octocatalog-diff/cli/options/facts_terminus.rb).

### Create test for option parser

Option parser tests are created in [`spec/octocatalog-diff/tests/cli/options`](/spec/octocatalog-diff/tests/cli/options).

If you used an existing option as a reference for your new code, consider using that option's test as a reference for your test. We have some methods, e.g. `test_with_true_false_option`, to avoid repetitive code for common patterns.

If you have handled any edge cases, e.g. input validation, please add a test that expects an error when input is provided that does not match your validation. For example, look at [`parser_spec.rb`](/spec/octocatalog-diff/tests/cli/options/parser_spec.rb).

### Add default value (OPTIONAL)

Unless specifically cleared with the project maintainers, adding a new option should not change the behavior of the program when that option isn't specified, and the new option should not be required.

In other words, if someone invokes the program *without* specifying your option, it should behave in the same way as it did before your option was ever added.

If you need to set a default value for your option, do so in [`lib/octocatalog-diff/cli.rb`](/lib/octocatalog-diff/cli.rb). Items should be added to DEFAULT_OPTIONS *only if* a value is required even if your option is not provided, or if you are defaulting something to *true* but providing an option to make it false.

### Add configuration example (OPTIONAL)

If you believe your option is of general use to other users of octocatalog-diff such that they may wish to add it to their configuration file, update [`examples/octocatalog-diff.cfg.rb`](/examples/octocatalog-diff.cfg.rb) with some comments and example code for your option.

Only the most commonly used options have entries in the example configuration file. If you are unsure whether or not to include your option there, please [open an issue](https://github.com/github/octocatalog-diff/issues/new) to discuss.

As described in the default value section above, if your option is not configured in the template, the program should still work as it did before your new option was added. We want to avoid forcing users to update their configuration file unless there is a major update.

### Add code to implement your option

This is for you to figure out! :smile_cat:

### Add corresponding tests for code

Please add unit tests in [`spec/octocatalog-diff/tests`](/spec/octocatalog-diff/tests) that test the new behavior of any methods impacted by your changes.

### Add an integration test (OPTIONAL)

Adding an integration test is optional, but very much appreciated.

Integration tests are in [`spec/octocatalog-diff/integration`](/spec/octocatalog-diff/integration). Generally, if you're adding a new option, the integration test for that new option will go in its own file.

Please see [integration tests](/doc/dev/integration-tests.md) for more.
