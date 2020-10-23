#!/usr/bin/env bash

# Purpose:
#  To compare the runtime bytecode of the current spell (src/DssSpell.sol) as
#  output by the compiler against the onchain bytecode of a provided contract
#  address. Can be used to verify that the deployed bytecode is correct even 
#  if Etherscan is down.
#
# Prerequisites:
#  Your ETH_RPC_URL environment variable must be set to an Ethereum node
#  endpoint exposing the getCode API. You should also compile the current spell
#  by running 'make' if needed.
#
# Arguments:
#  $1 : address of on-chain spell
#
# Example usage:
#  ./compare-bytecode.sh 0xb04A29de213411DDb7196eD1327b3B6144893E59
#
# Output:
#  A message stating whether the locally compiled spell matches the specified
#  contract, or possibly some sort of weird error.

COMPILED_BYTECODE=0x`jq '.contracts|.["src/DssSpell.sol:DssSpell"]|.["bin-runtime"]' ./out/dapp.sol.json | sed 's/"//g'`
ONCHAIN_BYTECODE=`curl -s --data '{"method": "eth_getCode", "params":["'${1}'", "latest"], "id":1, "jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST ${ETH_RPC_URL} | jq '.result' | sed 's/"//g'`
if [ "$COMPILED_BYTECODE" = "$ONCHAIN_BYTECODE" ] ; then
    echo -e "\e[32mSUCCESS! \e[39mBytecodes match."
else
    echo -e "\e[31mFAILURE. \e[39mBytecodes do NOT match."
fi
