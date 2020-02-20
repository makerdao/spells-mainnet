#!/usr/bin/env bash
set -e

[[ "$ETH_RPC_URL" && "$(seth chain)" == "ethlive" ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1; }

dapp --use solc:0.5.12 build
export DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7
export DAPP_TEST_TIMESTAMP=$(seth block latest timestamp)
export DAPP_TEST_NUMBER=$(seth block latest number)
LANG=C.UTF-8 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "testFeb21IncreaseDelay" --verbose 1
