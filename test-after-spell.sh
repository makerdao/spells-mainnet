#!/usr/bin/env bash

[[ "$ETH_RPC_URL" && "$(seth chain)" == "ethlive" ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1; }

dapp build 

LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "testSpellIsCasted" --verbose 1

LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "testFailSpellCast" --verbose 1

LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "testCreateETHVault" --verbose 1

LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "testCreateBATVault" --verbose 1

LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "testSwapSaiToDaiAndBack" --verbose 1

LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "testCDPMigrationPayWithMKR" --verbose 1

LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "testCDPMigrationPayWithDebt" --verbose 1
