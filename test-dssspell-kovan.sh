#!/usr/bin/env bash
set -e

#[[ "$ETH_RPC_URL" && "$(seth chain)" == "ethlive" ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1; }

dapp --use solc:0.5.12 build

export DAPP_TEST_ADDRESS=0xdb33dfd3d61308c33c63209845dad3e6bfb2c674
export DAPP_TEST_TIMESTAMP=$(seth block latest timestamp)
export DAPP_TEST_NUMBER=$(seth block latest number)

LANG=C.UTF-8 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "test" --verbose 1
