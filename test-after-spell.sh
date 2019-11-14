#!/usr/bin/env bash

set -e

[[ $ETH_RPC_URL  ]] || { echo "Please set an ETH_RPC_URL"; exit 1; }
# [[ $1 ]] && MATCH="--match $1"
dapp build 

LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 hevm dapp-test --rpc=$ETH_RPC_URL --json-file=out/dapp.sol.json --dapp-root=. --match "testSpellIsCasted"

LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 hevm dapp-test --rpc=$ETH_RPC_URL --json-file=out/dapp.sol.json --dapp-root=. --match "testFailSpellSchedule"
