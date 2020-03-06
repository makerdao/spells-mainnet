#!/usr/bin/env bash
set -e

[[ "$ETH_RPC_URL" && "$(seth chain)" == "ethlive" ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1; }

dapp build


function clean() {
  unset LANG
  unset DAPP_TEST_ADDRESS;
  unset DAPP_TEST_NUMBER;
  # rm -rf "state";
}

trap clean EXIT
export LANG=C.UTF-8
# Need to act from Multisig
export DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7
# Spell Contract contract launched at block 9010374
export DAPP_TEST_NUMBER=9010374

function test() {
    hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "$1" --verbose 1
}

test "testFlopSpellIsCast"
test "testFlopSpellSetup"
