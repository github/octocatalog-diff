#!/bin/bash

# This script is called from lib/octocatalog-diff/catalog-util/git.rb and is used to
# archive and extract a certain branch of a git repository into a target directory.

if [ -z "$OCD_GIT_EXTRACT_BRANCH" ]; then
  echo "Error: Must declare OCD_GIT_EXTRACT_BRANCH"
  exit 255
fi

if [ -z "$OCD_GIT_EXTRACT_TARGET" ]; then
  echo "Error: Must declare OCD_GIT_EXTRACT_TARGET"
  exit 255
fi

set -euf -o pipefail
git archive --format=tar "$OCD_GIT_EXTRACT_BRANCH" | ( cd "$OCD_GIT_EXTRACT_TARGET" && tar -xf - )
