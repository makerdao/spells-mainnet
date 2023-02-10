#!/usr/bin/env bash
set -e

[[ "$(cast chain --rpc-url="$ETH_RPC_URL")" == "ethlive" ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1; }

[[ "$1" =~ 0x* ]] || { echo "Please specify the transaction to inspect (e.g. tx=0x<txhash>)"; exit 1; }

for ARGUMENT in "$@"
do
    KEY=$(echo "$ARGUMENT" | cut -f1 -d=)
    VALUE=$(echo "$ARGUMENT" | cut -f2 -d=)

    case "$KEY" in
            tx)      TXHASH="$VALUE" ;;
            *)       TXHASH="$KEY"
    esac
done

echo -e "Network: $(cast chain)"
echo "timestamp: $(cast block "$(cast tx "${TXHASH}"|grep blockNumber|awk '{print $2}')"|grep timestamp|awk '{print $2}')"
echo "block: $(cast tx "${TXHASH}"|grep blockNumber|awk '{print $2}')"
