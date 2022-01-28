#!/usr/bin/env bash
set -e

[[ "$(seth chain --rpc-url=$ETH_RPC_URL)" == "ethlive"  ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1;  }

for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)

    case "$KEY" in
            match)      MATCH="$VALUE" ;;
            optimizer)  OPTIMIZER="$VALUE" ;;
            *)
    esac
done

if [[ -z "$OPTIMIZER" ]]; then
  # Default to running with optimize=1
  OPTIMIZER=1
fi

# 2022-01-28 Disabled optimizer on due to engineering costs
# export DAPP_BUILD_OPTIMIZE="$OPTIMIZER"
# export DAPP_BUILD_OPTIMIZE_RUNS=1

export DAPP_LIBRARIES=' lib/dss-exec-lib/src/DssExecLib.sol:DssExecLib:0xfD88CeE74f7D78697775aBDAE53f9Da1559728E4'
export DAPP_LINK_TEST_LIBRARIES=0

if [[ -z "$MATCH" ]]; then
  dapp --use solc:0.6.12 test --rpc-url="$ETH_RPC_URL" -v
else
  dapp --use solc:0.6.12 test --rpc-url="$ETH_RPC_URL" --match "$MATCH" -vv
fi
