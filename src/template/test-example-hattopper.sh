#!/usr/bin/env bash

[[ "$ETH_RPC_URL" && "$(seth chain)" == "ethlive" ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1; }

dapp build

function clean() { rm -rf "state"; }

trap clean EXIT
export LANG=C.UTF-8
# Need to act from Multisig
export DAPP_TEST_TIMESTAMP=$(seth block latest timestamp)
export DAPP_TEST_NUMBER=$(seth block latest number)

# Create Fake Multisig proxy actor so we can mint MKR (multisig address: 0x8EE7D9235e01e6B42345120b5d270bdB763624C7)
DIR="state/0x8EE7D9235e01e6B42345120b5d270bdB763624C7"
mkdir -p "$DIR"
cd $DIR || exit 1
# Simple Proxy with doMint(address gov, address dst, uint wad)
echo "608060405234801561001057600080fd5b506004361061002b5760003560e01c8063396eaa9314610030575b600080fd5b61009c6004803603606081101561004657600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190803573ffffffffffffffffffffffffffffffffffffffff1690602001909291908035906020019092919050505061009e565b005b8273ffffffffffffffffffffffffffffffffffffffff166340c10f1983836040518363ffffffff1660e01b8152600401808373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200182815260200192505050600060405180830381600087803b15801561012557600080fd5b505af1158015610139573d6000803e3d6000fd5b5050505050505056fea265627a7a72315820fac279dee69503a8fd261542b8394d05164fc8a8f27672073f37ef0ee168b26364736f6c634300050c0032" > code
cd ..
git init
git add .
git commit -m "-"
cd ..
hevm dapp-test --state="state/" --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "test_ExampleTestFromMultisig" --verbose 1

clean
# Need to act from Multisig, to prove this works for now,
# so we can setOwner=address(0) before minting
export DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7
# When the multisig is no longer owner of the MKR contract,
# this should be switched for 0x0000000000000000000000000000000000000000
DIR="state/0x0000000000000000000000000000000000000000"
mkdir -p "$DIR"
cd $DIR || exit 1
# Simple Proxy with doMint(address gov, address dst, uint wad)
echo "608060405234801561001057600080fd5b506004361061002b5760003560e01c8063396eaa9314610030575b600080fd5b61009c6004803603606081101561004657600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190803573ffffffffffffffffffffffffffffffffffffffff1690602001909291908035906020019092919050505061009e565b005b8273ffffffffffffffffffffffffffffffffffffffff166340c10f1983836040518363ffffffff1660e01b8152600401808373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200182815260200192505050600060405180830381600087803b15801561012557600080fd5b505af1158015610139573d6000803e3d6000fd5b5050505050505056fea265627a7a72315820fac279dee69503a8fd261542b8394d05164fc8a8f27672073f37ef0ee168b26364736f6c634300050c0032" > code
cd ..
git init
git add .
git commit -m "-"
cd ..
hevm dapp-test --state="state/" --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "test_ExampleTestFrom0" --verbose 1
