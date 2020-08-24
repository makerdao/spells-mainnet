#! /usr/bin/env bash

set -e

function message() {
    echo
    echo -----------------------------------
    echo "$@"
    echo -----------------------------------
    echo
}

message BUILDING DOCKER IMAGE
docker build -t makerdao/dss-launch-test .

message RUNNING TESTS
docker run --rm -it -e ETH_RPC_URL=${ETH_RPC_URL} makerdao/dss-launch-test
