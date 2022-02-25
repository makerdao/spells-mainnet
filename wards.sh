#!/usr/bin/env bash
set -e

[[ "$ETH_RPC_URL" ]] || { echo "Please set a ETH_RPC_URL"; exit 1; }

[[ "$1" ]] || { echo "Please specify the Target Address or ChainLog Key (ASCII) to inspect"; exit 1; }

### Override maxFeePerGas to avoid spikes
baseFee=$(seth basefee)
[[ -n "$ETH_GAS_PRICE" ]] && ethGasPriceLtBaseFee=$(echo "$ETH_GAS_PRICE < $baseFee" | bc)
[[ "$ethGasPriceLtBaseFee" == 1 ]] && export "ETH_GAS_PRICE=$(echo "$baseFee * 3" | bc)"

CHANGELOG=0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F

if [[ "$1" =~ 0x* ]]; then
    target=$1
else
    KEY=$(seth --to-bytes32 "$(seth --from-ascii "$1")")
    target=$(seth call "$CHANGELOG" 'getAddress(bytes32)(address)' "$KEY")
fi

echo -e "Network: $(seth chain)"
list=$(seth call "$CHANGELOG" 'list()(bytes32[])')
for key in $(echo -e "$list" | sed "s/,/ /g")
do
    contractName=$(seth --to-ascii "$key" | sed 's/\x0/ /g')
    contract=$(seth call "$CHANGELOG" 'getAddress(bytes32)(address)' "$key")
    wards=$(seth call "$contract" 'wards(address)(uint256)' "$target" 2>/dev/null) || continue
    [[ "$wards" == "1" ]] && echo "$contractName"
    src=$(seth call "$contract" 'src()(address)' 2>/dev/null) || continue
    srcWards=$(seth call "$src" 'wards(address)(uint256)' "$target" 2>/dev/null) || continue
    [[ "$srcWards" == "1" ]] && echo -e "source of $contractName\n$src"
done
