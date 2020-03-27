#!/usr/bin/env bash
set -e

[[ "$ETH_RPC_URL" && "$(seth chain)" == "ethlive" ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1; }

dapp --use solc:0.5.12 build

# MkrAuthority
#export DAPP_TEST_ADDRESS=0x6eEB68B2C7A918f36B78E2DB80dcF279236DDFb8
# MCD_FLOP
export DAPP_TEST_ADDRESS=0x4D95A049d5B0b7d32058cd3F2163015747522e99
export DAPP_TEST_TIMESTAMP=$(seth block latest timestamp)
export DAPP_TEST_NUMBER=$(seth block latest number)

LANG=C.UTF-8 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --verbose 1
