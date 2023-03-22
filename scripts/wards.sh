#!/usr/bin/env bash
set -e

[[ "$ETH_RPC_URL" ]] || { echo "Please set a ETH_RPC_URL"; exit 1; }

[[ "$1" ]] || { echo "Please specify the Target Address (e.g. target=0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B) or ChainLog Key (e.g. target=MCD_VAT) to inspect"; exit 1; }

for ARGUMENT in "$@"
do
    KEY=$(echo "$ARGUMENT" | cut -f1 -d=)
    VALUE=$(echo "$ARGUMENT" | cut -f2 -d=)

    case "$KEY" in
            target)      TARGET="$VALUE" ;;
            *)           TARGET="$KEY"   ;;
    esac
done

### Override maxFeePerGas to avoid spikes
baseFee=$(cast basefee)
[[ -n "$ETH_GAS_PRICE" ]] && ethGasPriceLtBaseFee=$(echo "$ETH_GAS_PRICE < $baseFee" | bc)
[[ "$ethGasPriceLtBaseFee" == 1 ]] && export "ETH_GAS_PRICE=$(echo "$baseFee * 3" | bc)"

CHANGELOG=0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F

if [[ "$TARGET" =~ 0x* ]]; then
    target=$TARGET
else
    key=$(cast --to-bytes32 "$(cast --from-ascii "$TARGET")")
    target=$(cast call "$CHANGELOG" 'getAddress(bytes32)(address)' "$key")
fi

echo -e "Network: $(cast chain)"
list=$(cast call "$CHANGELOG" 'list()(bytes32[])' | sed 's/[][]//g')
IFS=","
for key in $list
do
    contractName=$(cast --to-ascii "$key" | tr -d '\0')
    contract=$(cast call "$CHANGELOG" 'getAddress(bytes32)(address)' "$key")
    [[ $(cast call "$target" 'wards(address)(uint256)' "$contract" 2>/dev/null) == "1" ]] && echo "$1 -> $contractName"
    [[ $(cast call "$contract" 'wards(address)(uint256)' "$target" 2>/dev/null) == "1" ]] && echo "$contractName -> $1"
    src=$(cast call "$contract" 'src()(address)' 2>/dev/null) || continue
    [[ $(cast call "$src" 'wards(address)(uint256)' "$target" 2>/dev/null) == "1" ]] && echo "$src (source of $contractName) -> $1"
done
