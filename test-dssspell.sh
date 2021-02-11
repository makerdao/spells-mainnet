#!/usr/bin/env bash
set -e

[[ "$ETH_RPC_URL" && "$(seth chain)" == "ethlive"  ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1;  }

if [[ -z "$1" ]]; then
  dapp --use solc:0.6.11 test --rpc
else
  dapp --use solc:0.6.11 test --rpc --match "$1"
fi
