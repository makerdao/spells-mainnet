#!/usr/bin/env bash
set -e

[[ "$ETH_RPC_URL" && "$(seth chain)" == "ethlive" ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1; }

dapp --use solc:0.5.12 build
export DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 # Multisig so we have some MKR
export DAPP_TEST_TIMESTAMP=1580315248 # seth block latest timestamp at approximately 2020/01/28 ~15:56 ET
export DAPP_TEST_NUMBER=9378162 # latest blocknumber at timestamp

function test() {
    LANG=C.UTF-8 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "$1" --verbose 1
}

test "testDssFirstFlap"
test "testDssFlapAuction"
