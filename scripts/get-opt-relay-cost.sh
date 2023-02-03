#!/usr/bin/env bash
set -e
trap 'kill $(jobs -p) 2>/dev/null' EXIT

[[ "$(cast chain --rpc-url="$ETH_RPC_URL")" == "ethlive" ]] || { echo "Please set a Mainnet ETH_RPC_URL"; exit 1; }

OPTIMISM_GOERLI_RPC_URL='https://mainnet.optimism.io'

L2_SPELL='0x9495632F53Cc16324d2FcFCdD4EB59fb88dDab12'
CHANGELOG='0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F'
X_DOMAIN_MSG_SENDER_SLOT=4 # Note: this becomes 204 after the Bedrock update!

L1_GOV_RELAY=$(
    cast call "$CHANGELOG" "getAddress(bytes32)(address)" \
    "$(cast --format-bytes32-string "OPTIMISM_GOV_RELAY")"
)
L2_GOV_RELAY=$(cast call "$L1_GOV_RELAY" "l2GovernanceRelay()(address)")
L2_MESSENGER=$(cast call --rpc-url="$OPTIMISM_GOERLI_RPC_URL" "$L2_GOV_RELAY" "messenger()(address)")

PORT=8555
LOCALHOST="http://127.0.0.1:$PORT"

anvil -f "$OPTIMISM_GOERLI_RPC_URL" -p "$PORT" > /dev/null 2>&1 &
sleep 20

cast rpc --rpc-url="$LOCALHOST" anvil_setStorageAt "$L2_MESSENGER" \
    "$(printf 0x"%064X\n" "$X_DOMAIN_MSG_SENDER_SLOT")" \
    "$(printf 0x"%064s\n" "${L1_GOV_RELAY:2}" | tr ' ' 0)" > /dev/null
OPT_GAS=$(
    cast estimate --rpc-url="$LOCALHOST" --from "$L2_MESSENGER" \
    "$L2_GOV_RELAY" \
    "relay(address,bytes)" \
    "$L2_SPELL" \
    "$(cast calldata 'execute()')"
)

echo "OPT_GAS = $OPT_GAS"
