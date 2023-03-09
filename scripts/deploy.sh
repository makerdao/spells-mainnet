#!/usr/bin/env bash
set -e
trap 'git stash pop' EXIT

# Colors
YELLOW="\033[0;33m"
PURPLE="\033[0;35m"
NC="\033[0m"

# stash any changes in the staging area
echo -e "${YELLOW}Stashing any changes to${NC} ${PURPLE}src/test/config.sol${NC}"
(set -x; git stash push src/test/config.sol)

[[ "$ETH_RPC_URL" && "$(cast chain)" == "ethlive" && "$(cast chain-id)" == "1" ]] || { echo -e "${YELLOW}Please set a ${NC}${PURPLE}Mainnet ETH_RPC_URL${NC}"; exit 1; }
[[ "$ETHERSCAN_API_KEY" ]] || { echo -e "${YELLOW}Please set ${NC}${PURPLE}ETHERSCAN_API_KEY${NC}"; exit 1; }

SOURCE="src/test/config.sol"
KEY_SPELL="deployed_spell"
KEY_TIMESTAMP="deployed_spell_created"
KEY_BLOCK="deployed_spell_block"

make && spell_address=$(dapp create DssSpell)

./scripts/verify.py DssSpell "$spell_address"

# edit config.sol to add the deployed spell address
sed -Ei "s/($KEY_SPELL: *address\()(0x[[:xdigit:]]{40}|0x0|0)\)/\1$spell_address)/" "$SOURCE"

# get tx hash from contract address, created using an internal transaction
TXHASH=$(curl "https://api.etherscan.io/api?module=account&action=txlistinternal&address=$spell_address&startblock=0&endblock=99999999&sort=asc&apikey=$ETHERSCAN_API_KEY" | jq -r ".result[0].hash")

# get deployed contract timestamp and block number info
timestamp=$(cast block "$(cast tx "${TXHASH}"|grep blockNumber|awk '{print $2}')"|grep timestamp|awk '{print $2}')
block=$(cast tx "${TXHASH}"|grep blockNumber|awk '{print $2}')

# edit config.sol to add the deployed spell timestamp and block number
sed -i "s/\($KEY_TIMESTAMP *: *\)[0-9]\+/\1$timestamp/" "$SOURCE"
sed -i "s/\($KEY_BLOCK *: *\)[0-9]\+/\1$block/" "$SOURCE"

echo -e "${YELLOW}Network: $(cast chain)${NC}"
echo -e "${YELLOW}config.sol updated with ${PURPLE}deployed spell:${NC} $spell_address, ${PURPLE}timestamp:${NC} $timestamp and ${PURPLE}block:${NC} $block ${NC}"

make test block="$block" || { echo -e "${PURPLE}Ensure Tests PASS before commiting the config.sol changes${NC}"; exit 1; }

# commit edit change to config.sol
if [[ $(git status --porcelain src/test/config.sol) ]]; then
    (set -x; git commit -m "add deployed spell info" -- src/test/config.sol)
else
    echo -e "${PURPLE}Ensure config.sol was edited correctly${NC}"
    exit 1
fi
