# Releasing

The project maintainers are responsible for bumping the version number, regenerating auto-generated documentation, tagging the release, and uploading to rubygems.

## Local testing

To test the new version of `octocatalog-diff` in the Puppet repository:

0. In the Puppet checkout, start a new branch based off master.
0. In the `octocatalog-diff` checkout:
  - Ensure that the desired branch is checked out.
  - Choose a unique internal version number which has never been used in CI. A good guideline is that if you're planning to release a version `0.6.0` then for these tests, use `0.6.0a`, `0.6.0b`, ...
  - Build the gem using your internal version number:

    ```
    OCTOCATALOG_DIFF_VERSION=0.6.0a rake gem:force-build
    ```
  - Run the task to install the gem into your Puppet checkout:

    ```
    OCTOCATALOG_DIFF_VERSION=0.6.0a rake gem:localinstall
    ```

0. Back in the Puppet checkout, ensure that the changes are as expected (updates to Gemfile / Gemfile.lock, addition of new gem). Push the change and build appropriate CI job(s) to validate the changes.

## Merging

0. If necessary, complete a Pull Request to update the [version file](/.version).
0. If necessary, auto-generate the build documentation.

  ```
  rake doc:build
  ```

0. Ensure that CI tests are all passing.
0. Merge and delete the branch.

## Releasing

Generally, a new release will correspond to a merge to master of one or more Pull Requests.

0. Ensure that all changes associated with the release have been merged to master.
  - Merge all Pull Requests associated with release.
  - If necessary, complete a Pull Request to update the [change log](/doc/CHANGELOG.md).
  - If necessary (for significant changes), complete a Pull Request to update the top-level README file.
0. Ensure the the master branch is checked out on your system.
0. Run the release procedure:

  ```
  rake gem:release
  ```

This rake task handles the following:

- Build the gem file (`rake gem:build`)
- Tag the release in the repository (`rake gem:tag`)
- Upload the gem file to rubygems (`rake gem:push`)
