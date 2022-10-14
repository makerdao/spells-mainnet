#!/usr/bin/env bash
set -e

[[ "$ETH_RPC_URL" && "$(cast chain)" == "ethlive" && "$(cast chain-id)" == "1" ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1; }
[[ "$ETHERSCAN_API_KEY" ]] || { echo "Please set a ETHERSCAN_API_KEY"; exit 1; }

make && \
  dapp create DssSpell | \
  xargs ./scripts/verify.py DssSpell
