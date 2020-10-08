#! /usr/bin/env bash

set -e

function message() {
    echo
    echo -----------------------------------
    echo "$@"
    echo -----------------------------------
    echo
}

message RUNNING TESTS
docker build -t makerdao/spells-mainnet-test . && docker run --rm -it -e ETH_RPC_URL=${ETH_RPC_URL} makerdao/spells-mainnet-test
