#!/usr/bin/env bash
set -e

[[ "$ETH_RPC_URL" && "$(seth chain)" == "ethlive"  ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1;  }

export DAPP_LIBRARIES=' lib/dss-exec-lib/src/DssExecLib.sol:DssExecLib:0x25dA9Fce914fa6914631add105d83691E19e23a3'
export DAPP_LINK_TEST_LIBRARIES=0

if [[ -z "$1" ]]; then
  dapp --use solc:0.6.11 test --rpc-url="$ETH_RPC_URL" -v
else
  dapp --use solc:0.6.11 test --rpc-url="$ETH_RPC_URL" --match "$1" -vv
fi
