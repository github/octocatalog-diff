#!/bin/bash

# Script to determine the Puppet version.

if [ -z "$OCD_PUPPET_BINARY" ]; then
  echo "Error: PUPPET_BINARY must be set"
  exit 255
fi

"$OCD_PUPPET_BINARY" --version
