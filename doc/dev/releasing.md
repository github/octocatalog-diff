# Releasing

The project maintainers are responsible for bumping the version number, regenerating auto-generated documentation, tagging the release, and uploading to rubygems.

## Local testing

*This procedure is performed by a GitHubber.*

To test the new version of `octocatalog-diff` in the GitHub Puppet repository, check out `github/puppet` and:

- Start a new branch based off master
- Run `script/update-octocatalog-diff <ocd_branch_name>`
- Confirm and commit the result
- Make sure all CI jobs pass
- Run the `puppet-catalog-diff` CI job and make sure it passes and shows expected results

## Merging one PR

This section is useful when releasing a new version based on one PR submitted by a contributor. Following this workflow is important so that the contributor gets appropriate credit in the revision history for his or her work.

1. In your local checkout, start a new branch based off master.
1. Add the contributor's repository as a remote. For example:

    ```
    git remote add octocat https://github.com/octocat/octocatalog-diff.git
    ```

1. Merge in the contributor's branch into your own. For example:

    ```
    git merge octocat/some-branch
    ```

1. Update `.version` and `doc/CHANGELOG.md` appropriately. In CHANGELOG you should link to the PR submitted by the contributor (not the PR you're creating now).
1. Commit your changes to `.version` and `doc/CHANGELOG.md`.
1. If necessary, auto-generate the build documentation, and commit the changes to your branch.

    ```
    rake doc:build
    ```

1. Open a Pull Request based on your branch. Confirm that the history is correct, showing the contributor's commits first, and then your commit(s) updating the version file, change log, and/or auto-generated documentation.
1. Ensure that CI tests are all passing.
1. Ensure that you've performed "local testing" within GitHub (typically, ~1 day) to confirm the changes.
1. Merge your PR and delete your branch.
1. Confirm that the contributor's PR now appears as merged, and any associated issues have been closed.

## Merging multiple PRs

If multiple PRs will constitute a release, it's generally easier to merge each such PR individually, and then create a separate PR afterwards to update the necessary files.

1. Merge all constituent PRs and ensure that any associated issues have been closed.
1. Create your own branch based off master.
1. Update `.version` and `doc/CHANGELOG.md` appropriately. In CHANGELOG you should link to the PR submitted by the contributor (not the PR you're creating now).
1. Commit your changes to `.version` and `doc/CHANGELOG.md`.
1. If necessary, auto-generate the build documentation, and commit the changes to your branch.

    ```
    rake doc:build
    ```

1. Open a Pull Request based on your branch.
1. Ensure that CI tests are all passing.
1. Ensure that you've performed "local testing" within GitHub (typically, ~1 day) to confirm the changes.
1. Merge your PR and delete your branch.

## Releasing

Generally, a new release will correspond to a merge to master of one or more Pull Requests.

1. Ensure that all changes associated with the release have been merged to master.
    - Merge all Pull Requests associated with release, including the version number bump, change log update, etc.
    - If necessary (for significant changes), complete a Pull Request to update the top-level README file.
1. Ensure the the master branch is checked out on your system.
1. Run the release procedure:

    ```
    rake gem:release
    ```

This rake task handles the following:

- Build the gem file (`rake gem:build`)
- Tag the release in the repository (`rake gem:tag`)
- Upload the gem file to rubygems (`rake gem:push`)
