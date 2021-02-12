#!/usr/bin/env bash
set -e

[[ "$ETH_RPC_URL" && "$(seth chain)" == "ethlive"  ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1;  }

export DAPP_STANDARD_JSON="config.json"
export DAPP_LINK_TEST_LIBRARIES=0

if [[ -z "$1" ]]; then
  dapp --use solc:0.6.11 test --rpc-url="$ETH_RPC_URL" -v
else
  dapp --use solc:0.6.11 test --rpc-url="$ETH_RPC_URL" --match "$1" -vv
fi
