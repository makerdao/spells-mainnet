#!/usr/bin/env bash

SPELL="DssReplaceFlipper"
SPELLFILE="${SPELL}.sol"
TESTFILE="${SPELL}.t.sol"

dapp --use solc:0.5.12 build --extract

flipper_addr=$(seth --to-checksum-address $(dapp create $SPELL))

# mainnet multisig
# export DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7
# kovan deployer
export DAPP_TEST_ADDRESS=0xdB33dFD3D61308C33C63209845DaD3e6bfb2c674
export DAPP_TEST_TIMESTAMP=$(seth block latest timestamp)
export DAPP_TEST_NUMBER=$(seth block latest number)
LANG=C.UTF-8 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "test" --verbose 1
