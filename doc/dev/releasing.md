# Releasing

The project maintainers are responsible for bumping the version number, regenerating auto-generated documentation, tagging the release, and uploading to rubygems.

0. Ensure that all changes have been merged to master.
0. If necessary, complete a Pull Request to update the [version file](/.version).
0. Ensure the the master branch is checked out on your system.
0. Run the release procedure:

  ```
  rake gem:release
  ```

This rake task handles the following:

- Auto-generates the [options reference](/doc/optionsref.md) (`rake doc:build`)
- Build the gem file (`rake gem:build`)
- Tag the release in the repository (`rake gem:tag`)
- Upload the gem file to rubygems (`rake gem:push`)
