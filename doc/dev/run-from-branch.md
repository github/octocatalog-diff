# Running octocatalog-diff from a branch

When we are assisting with troubleshooting, or implementing a feature you've requested, we may ask you to run `octocatalog-diff` from a non-master branch to try it out.

This document is intended for people who may not be familiar with git, GitHub, and/or ruby. If you already know how to do this in another way, feel free!

## Installation

1. Determine the branch name. If there's an open Pull Request, you can see the branch name near the top of the page.

  ![Pull Request branch](/doc/images/pull-request-identify-branch.png)

2. Clone the `octocatalog-diff` repository in your home directory. From the command line:

  ```
  cd $HOME
  git clone https://github.com/github/octocatalog-diff.git
  ```

3. Change into the directory created by your checkout:

  ```
  cd $HOME/octocatalog-diff
  ```

4. Check out the branch you wish to use, filling in the branch name you determined in the first step:

  ```
  git checkout BRANCH_NAME_FROM_STEP_1
  ```

5. Bootstrap the repository to pull in dependencies:

  ```
  ./script/bootstrap
  ```

6. Optional but recommended - run the test suite:

  ```
  rake
  ```

## Use

Now that you have `octocatalog-diff` checked out and bootstrapped, it's time to use it.

We've created a wrapper script to make this easier for you.

1. Change directories to the location where you ordinarily run `octocatalog-diff` (for example: in your Puppet repository).

2. Run the `script/octocatalog-diff-wrapper` script from *this* checkout. For example, if you checked out `octocatalog-diff` to your home directory, you could use:

```
$HOME/octocatalog-diff/script/octocatalog-diff-wrapper <options>
```

:warning: Note: If you are requesting our help, please use the debug option (`-d`) to display debugging information.
