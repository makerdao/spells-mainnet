#!/usr/bin/env bash

[[ "$ETH_RPC_URL" && "$(seth chain)" == "ethlive" ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1; }

dapp build

# LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "test_canAddMkrAuth" # --verbose 1

# LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "test_canRemoveOwner" # --verbose 1

LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "testFail_cannotDealFlop" # --verbose 1
LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "test_canDealFlop_stuck" # --verbose 1
LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "test_canDealFlop_new" # --verbose 1
