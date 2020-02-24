#!/usr/bin/env bash
set -e

[[ "$ETH_RPC_URL" && "$(seth chain)" == "ethlive" ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1; }

dapp --use solc:0.5.12 build
# using the chief not multisig
export DAPP_TEST_ADDRESS=0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5
export DAPP_TEST_TIMESTAMP=$(seth block latest timestamp)
export DAPP_TEST_NUMBER=$(seth block latest number)
LANG=C.UTF-8 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "testFeb21IncreaseDelay" --verbose 1
