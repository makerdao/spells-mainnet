#!/usr/bin/env bash
set -e

./test-dssspell.sh
./compare-bytecode.sh
