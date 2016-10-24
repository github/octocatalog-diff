#!/bin/sh
ls -lR > /tmp/foo.$$
echo "Hello, stdout"
echo "Hello, stderr" 1>&2
cp -r external-modules/test modules
exit 0
