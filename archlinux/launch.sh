#!/usr/bin/env bash

#
# Just an example for using client tool, see https://jamesclonk.github.io/vultr/
#

vultr server create --name="vultrarch" --region=25 --plan=29 --os=159 \
  --iso=131567 --sshkey=57320a1e4f870 --script=18439 --ipv6=true \
  --private-networking=true
