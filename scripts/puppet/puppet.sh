#!/bin/bash

# Script to run Puppet. The default implementation here is simply to pass
# through the command line arguments (which are likely to be numerous when
# compiling a catalog).

if [ -z "$OCD_PUPPET_BINARY" ]; then
  echo "Error: PUPPET_BINARY must be set"
  exit 255
fi

"$OCD_PUPPET_BINARY" "$@"
