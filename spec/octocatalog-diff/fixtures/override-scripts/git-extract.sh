#!/bin/bash

# For test purposes only, this script would ordinarily run a git checkout, but here
# it's going to generate a directory structure by copying some other fixture.

if [ -z "$OCD_GIT_EXTRACT_BRANCH" ]; then
  echo "Error: Must declare OCD_GIT_EXTRACT_BRANCH"
  exit 255
fi

if [ -z "$OCD_GIT_EXTRACT_TARGET" ]; then
  echo "Error: Must declare OCD_GIT_EXTRACT_TARGET"
  exit 255
fi

if [ -z "$FIXTURE_DIR" ]; then
  echo "Error: Must declare FIXTURE_DIR"
  exit 255
fi

set -euf -o pipefail
cd "${FIXTURE_DIR}/${OCD_GIT_EXTRACT_BRANCH}"
tar -cf - . | ( cd "$OCD_GIT_EXTRACT_TARGET" && tar -xf - )
mkdir -p "$OCD_GIT_EXTRACT_TARGET/environments"
ln -s "$OCD_GIT_EXTRACT_TARGET" "$OCD_GIT_EXTRACT_TARGET/environments/production"
