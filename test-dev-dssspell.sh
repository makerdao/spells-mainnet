#!/usr/bin/env bash
set -e

[[ "$(seth chain --rpc-url=$ETH_RPC_URL)" == "ethlive"  ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1;  }

echo "Running tests with optimizations turned off"
export DAPP_BUILD_OPTIMIZE=0
export DAPP_BUILD_OPTIMIZE_RUNS=0
export DAPP_LIBRARIES=' lib/dss-exec-lib/src/DssExecLib.sol:DssExecLib:0xfD88CeE74f7D78697775aBDAE53f9Da1559728E4'
export DAPP_LINK_TEST_LIBRARIES=0

if [[ -z "$1" ]]; then
  dapp --use solc:0.6.12 test --rpc-url="$ETH_RPC_URL" -v
else
  dapp --use solc:0.6.12 test --rpc-url="$ETH_RPC_URL" --match "$1" -vv
fi
