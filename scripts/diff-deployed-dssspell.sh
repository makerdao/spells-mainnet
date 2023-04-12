#!/usr/bin/env bash

set -e

if [[ "$1" =~  ^0x[0-9a-fA-F]{40}$ ]]; then
    deployed_spell_address=$1
else
    # Read contract address from config.sol
    deployed_spell_address=$(grep -oE 'deployed_spell:\s+address\((0x[a-fA-F0-9]+)\)' "src/test/config.sol" | sed -E 's/^.*\((.*)\)/\1/')
    # Check if contract address, block number, and timestamp are zero
    [[ "$deployed_spell_address" =~ ^(address\(0\)|0)$ ]] && { echo "DssSpell address is not set in config file."; exit 1; }
fi

make all && make flatten

spell_source="out/flat.sol"

# Download the deployed spell source code from Etherscan API
spell_etherscan=$(curl -s "https://api.etherscan.io/api?module=contract&action=getsourcecode&address=$deployed_spell_address" | jq -r '.result[0].SourceCode')

# Compare the downloaded source code with the local spell
diff --color -u <(echo "$spell_etherscan") "$spell_source"

make clean
