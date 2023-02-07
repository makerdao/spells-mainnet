#!/usr/bin/env bash
set -e
trap 'kill $(jobs -p) 2>/dev/null' EXIT

[[ "$(cast chain --rpc-url="$ETH_RPC_URL")" == "ethlive" ]] || { echo "Please set a Mainnet ETH_RPC_URL"; exit 1; }

OPTIMISM_MAINNET_RPC_URL='https://mainnet.optimism.io'

L2_SPELL='0x9495632F53Cc16324d2FcFCdD4EB59fb88dDab12'
CHANGELOG='0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F'

PRE_BEDROCK_L1_MESSENGER_IMPL='0xd9166833FF12A5F900ccfBf2c8B62a90F1Ca1FD5'
OPT_ADDRESS_MANAGER='0xdE1FCfB0851916CA5101820A69b13a4E276bd81F'
L1_MESSENGER_IMPL=$(cast call "$OPT_ADDRESS_MANAGER" "getAddress(string)(address)" "OVM_L1CrossDomainMessenger")

L1_GOV_RELAY=$(
    cast call "$CHANGELOG" "getAddress(bytes32)(address)" \
    "$(cast --format-bytes32-string "OPTIMISM_GOV_RELAY")"
)
L2_GOV_RELAY=$(cast call "$L1_GOV_RELAY" "l2GovernanceRelay()(address)")
L2_MESSENGER=$(cast call --rpc-url="$OPTIMISM_MAINNET_RPC_URL" "$L2_GOV_RELAY" "messenger()(address)")

EXECUTE_CALLDATA=$(cast calldata 'execute()')

PORT=8555
LOCALHOST="http://127.0.0.1:$PORT"
anvil -f "$OPTIMISM_MAINNET_RPC_URL" -p "$PORT" > /dev/null 2>&1 &
sleep 20


if [[ "$L1_MESSENGER_IMPL" == "$PRE_BEDROCK_L1_MESSENGER_IMPL" ]]; then
    echo "Gas estimation performed for pre-Bedrock contracts"
    L1_MESSENGER=$(cast call "$L1_GOV_RELAY" "messenger()(address)")
    L1_MESSENGER_OFFSET="0x$(echo "obase=16;ibase=16;$(echo "${L1_MESSENGER:2} + 1111000000000000000000000000000000001111" | tr a-f A-F)" | bc)"
    OPT_GAS=$(
        cast estimate --rpc-url="$LOCALHOST" --from "$L1_MESSENGER_OFFSET" \
        "$L2_MESSENGER" \
        "relayMessage(address,address,bytes,uint256)" \
        "$L2_GOV_RELAY" \
        "$L1_GOV_RELAY" \
        "$(cast calldata "relay(address,bytes)" "$L2_SPELL" "$EXECUTE_CALLDATA")" \
        0
    )
else
    X_DOMAIN_MSG_SENDER_SLOT=204 # Note: this was slot "4" pre-Bedrock
    cast rpc --rpc-url="$LOCALHOST" anvil_setStorageAt "$L2_MESSENGER" \
        "$(printf 0x"%064X\n" "$X_DOMAIN_MSG_SENDER_SLOT")" \
        "$(printf 0x"%064s\n" "${L1_GOV_RELAY:2}" | tr ' ' 0)" > /dev/null
    OPT_GAS=$(
        cast estimate --rpc-url="$LOCALHOST" --from "$L2_MESSENGER" \
        "$L2_GOV_RELAY" \
        "relay(address,bytes)" \
        "$L2_SPELL" \
        "$EXECUTE_CALLDATA"
    )
fi

echo "OPT_GAS = $OPT_GAS"
