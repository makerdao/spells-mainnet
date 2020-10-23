#!/usr/bin/env bash

# Arguments:
#  $1 : address of on-chain spell
#
# Example:
#  ./compare-bytecode.sh 0xb04A29de213411DDb7196eD1327b3B6144893E59
#
# Output:
#  A message stating whether the locally compiled spell matches the specified contract, or some sort of weird error.

EXPECTED_BYTECODE=0x`jq '.contracts|.["src/DssSpell.sol:DssSpell"]|.["bin-runtime"]' ./out/dapp.sol.json | sed 's/"//g'`
ONCHAIN_BYTECODE=`curl -s --data '{"method": "eth_getCode", "params":["'${1}'", "latest"], "id":1, "jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST ${ETH_RPC_URL} | jq '.result' | sed 's/"//g'`
if [ "$EXPECTED_BYTECODE" = "$ONCHAIN_BYTECODE" ] ; then
    echo -e "\e[32mSUCCESS! \e[39mBytecodes match."
else
    echo -e "\e[31mFAILURE. \e[39mBytecodes do not match"
fi
