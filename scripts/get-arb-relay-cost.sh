#!/usr/bin/env bash
set -e

[[ "$(cast chain --rpc-url="$ETH_RPC_URL")" == "ethlive" ]] || { echo "Please set a Mainnet ETH_RPC_URL"; exit 1; }
[[ "$1" =~ ^0x[[:xdigit:]]{40}$ ]] || { echo "Please specify the Arbitrum spell address (e.g. 0x852CCBB823D73b3e35f68AD6b14e29B02360FD3d)"; exit 1; }
L2_SPELL=$1

ARBITRUM_MAINNET_RPC_URL='https://arb1.arbitrum.io/rpc'

CHANGELOG='0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F'
NODE_INTERFACE='0x00000000000000000000000000000000000000C8'

L1_GOV_RELAY=$(
    cast call "$CHANGELOG" "getAddress(bytes32)(address)" \
    "$(cast --format-bytes32-string "ARBITRUM_GOV_RELAY")"
)
L2_GOV_RELAY=$(cast call "$L1_GOV_RELAY" "l2GovernanceRelay()(address)")
INBOX=$(cast call "$L1_GOV_RELAY" "inbox()(address)")

BASE_FEE_SAFETY_FACTOR=20 # Factor by which L1 block.basefee could grow between now and the spell cast time

ARB_GAS_PRICE_BID=$(cast gas-price --rpc-url "$ARBITRUM_MAINNET_RPC_URL")
RELAY_CALLDATA=$(
    cast calldata "relay(address,bytes)" "$L2_SPELL" "$(cast calldata "execute()")"
)
ARB_MAX_GAS=$(
    cast estimate --rpc-url "$ARBITRUM_MAINNET_RPC_URL" \
    "$NODE_INTERFACE" \
    "estimateRetryableTicket(address,uint256,address,uint256,address,address,bytes)" \
    "$L1_GOV_RELAY" \
    1000000000000000000 \
    "$L2_GOV_RELAY" \
    0 \
    "$L2_GOV_RELAY" \
    "$L2_GOV_RELAY" \
    "$RELAY_CALLDATA"
)
RELAY_CALLDATA_LEN=$(( $(echo -n "$RELAY_CALLDATA" | wc -c) / 2 - 1 ))
SUBMISSION_FEE=$(
    cast call "$INBOX" \
    "calculateRetryableSubmissionFee(uint256,uint256)(uint256)" \
    "$RELAY_CALLDATA_LEN" \
    0
)
ARB_MAX_SUBMISSION_COST=$((SUBMISSION_FEE * BASE_FEE_SAFETY_FACTOR))
ARB_L1_CALL_VALUE=$((ARB_MAX_GAS * ARB_GAS_PRICE_BID + ARB_MAX_SUBMISSION_COST))

echo "ARB_MAX_GAS             = $ARB_MAX_GAS"
echo "ARB_GAS_PRICE_BID       = $ARB_GAS_PRICE_BID"
echo "ARB_MAX_SUBMISSION_COST = $ARB_MAX_SUBMISSION_COST"
echo "ARB_L1_CALL_VALUE       = $ARB_L1_CALL_VALUE"
