#!/usr/bin/env bash
set -e

[[ "$ETH_RPC_URL" && "$(seth chain)" == "ethlive"  ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1;  }

export DAPP_BUILD_OPTIMIZE=1
export DAPP_BUILD_OPTIMIZE_RUNS=1
export DAPP_LIBRARIES=' lib/dss-exec-lib/src/DssExecLib.sol:DssExecLib:0x3117D2CbA81fC118fc471D383Ab20F11939A3CfF'
export DAPP_LINK_TEST_LIBRARIES=0

if [[ -z "$1" ]]; then
  dapp --use solc:0.6.12 test --rpc-url="$ETH_RPC_URL" -v
else
  dapp --use solc:0.6.12 test --rpc-url="$ETH_RPC_URL" --match "$1" -vv
fi
