#!/bin/sh

set -e

env

ssh-add -l

/app/dev/script/build-server r3.4.24
