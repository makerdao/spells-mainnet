#!/usr/bin/env bash

set -e

[[ $ETH_RPC_URL  ]] || { echo "Please set an ETH_RPC_URL"; exit 1; }
# [[ $1 ]] && MATCH="--match $1"
dapp build 

LANG=C.UTF-8 hevm dapp-test --rpc "$ETH_RPC_URL" # --verbose 1
