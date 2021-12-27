#!/usr/bin/env bash
set -e

[[ "$(seth chain --rpc-url=$ETH_RPC_URL)" == "ethlive"  ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1;  }

if [[ -z "$1" ]]; then
  forge test --fork-url "$ETH_RPC_URL" --libraries "src/DssSpell.sol:DssExecLib:0xfD88CeE74f7D78697775aBDAE53f9Da1559728E4" --verbosity 3 --match "$1"
else
  forge test --fork-url "$ETH_RPC_URL" --libraries "src/DssSpell.sol:DssExecLib:0xfD88CeE74f7D78697775aBDAE53f9Da1559728E4" --verbosity 3
fi
