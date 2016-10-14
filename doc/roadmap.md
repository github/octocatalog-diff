# Roadmap

This document outlines our philosophy and goals for the continued development of `octocatalog-diff`.

## Goals

- Work on a system without a full Puppet installation
- Cause no added load on production Puppet masters (unless you specifically choose to do so with non-default options)
- Offer a command line tool to help make developers more efficient
- Offer the ability to in a Continuous Integration (CI) environment
- Be compatible with Puppet 3.8.7, 4.5, and later versions
- Provide flexibility to build and compare catalogs even in esoteric Puppet codebases

## Areas for future development

We are considering these areas for possible future development:

- Improved display of diffs, perhaps a web interface
- Additional CI use cases
- CI output display to summarize a change and a list of affected hosts, rather than listing all changes host-by-host

## Antipatterns

These are ideas we've evaluated and decided not to pursue. (If you are considering a [contribution](/.github/CONTRIBUTING.md) along these lines, please [open an issue](https://github.com/github/octocatalog-diff/issues/new) before start working on it. We would feel badly if you did a bunch of work that we could not accept.)

- Making this into a Puppet module with a "face" so that it can be run with `puppet octocatalog-diff ...` or similar. (We have specifically designed this tool to run without a full Puppet installation. There are [similar projects](/doc/similar.md) that are distributed as Puppet modules.)
