#!/usr/bin/env bash
set -e

[[ "$(seth chain --rpc-url="$ETH_RPC_URL")" == "ethlive" ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1; }

for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)

    case "$KEY" in
            match)      MATCH="$VALUE" ;;
            block)      BLOCK="$VALUE" ;;
            *)
    esac
done

export DAPP_LIBRARIES='src/DssSpell.sol:DssExecLib:0xfD88CeE74f7D78697775aBDAE53f9Da1559728E4'

if [[ -z "$MATCH" && -z "$BLOCK" ]]; then
    forge test --fork-url "$ETH_RPC_URL" --force
elif [[ -z "$BLOCK" ]]; then
    forge test --fork-url "$ETH_RPC_URL" --match "$MATCH" -vvv --force
elif [[ -z "$MATCH" ]]; then
    forge test --fork-url "$ETH_RPC_URL" --fork-block-number "$BLOCK" --force
else
    forge test --fork-url "$ETH_RPC_URL" --match "$MATCH" --fork-block-number "$BLOCK" -vvv --force
fi
