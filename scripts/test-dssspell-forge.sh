#!/usr/bin/env bash
set -e

[[ "$(cast chain --rpc-url="$ETH_RPC_URL")" == "ethlive" ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1; }

for ARGUMENT in "$@"
do
    KEY=$(echo "$ARGUMENT" | cut -f1 -d=)
    VALUE=$(echo "$ARGUMENT" | cut -f2 -d=)

    case "$KEY" in
            match)      MATCH="$VALUE" ;;
            block)      BLOCK="$VALUE" ;;
            *)
    esac
done

DSS_EXEC_LIB=$(< DssExecLib.address)
echo "Using DssExecLib at: $DSS_EXEC_LIB"
export FOUNDRY_LIBRARIES="lib/dss-exec-lib/src/DssExecLib.sol:DssExecLib:$DSS_EXEC_LIB"
export FOUNDRY_OPTIMIZER=false
export FOUNDRY_OPTIMIZER_RUNS=200
export FOUNDRY_ROOT_CHAINID=1

if [[ -z "$MATCH" && -z "$BLOCK" ]]; then
    forge test --fork-url "$ETH_RPC_URL"
elif [[ -z "$BLOCK" ]]; then
    forge test --fork-url "$ETH_RPC_URL" --match "$MATCH" -vvv
elif [[ -z "$MATCH" ]]; then
    forge test --fork-url "$ETH_RPC_URL" --fork-block-number "$BLOCK"
else
    forge test --fork-url "$ETH_RPC_URL" --match "$MATCH" --fork-block-number "$BLOCK" -vvv
fi
