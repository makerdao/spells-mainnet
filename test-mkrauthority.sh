#!/usr/bin/env bash

[[ "$ETH_RPC_URL" && "$(seth chain)" == "ethlive" ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1; }

dapp build

# MKRAuthority contract launched at block 9006819

# LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 DAPP_TEST_NUMBER=9006820 hevm dapp-test --state state/ --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "test_canAddMkrAuth" --verbose 1

function clean() { rm -rf "state"; }
trap clean EXIT
DIR="state/0xdDb108893104dE4E1C6d0E47c42237dB4E617ACc"
mkdir -p "$DIR"
cd $DIR || exit 1
# Simple Proxy with delegate call via execute(address,bytes memory)
echo "60806040526004361061001e5760003560e01c80631cff79cd14610020575b005b6100f96004803603604081101561003657600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff1690602001909291908035906020019064010000000081111561007357600080fd5b82018360208201111561008557600080fd5b803590602001918460018302840111640100000000831117156100a757600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f820116905080830192505050505050509192919290505050610174565b6040518080602001828103825283818151815260200191508051906020019080838360005b8381101561013957808201518184015260208101905061011e565b50505050905090810190601f1680156101665780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b6060600080835160208501866113885a03f43d6040519250601f19601f6020830101168301604052808352806000602085013e8115600181146101b6576101bd565b8160208501fd5b5050509291505056fea265627a7a72315820bc317882b7a046a7bb192a03f08f9a7470c8b752cfcb36b24aaf3126d5864a7864736f6c634300050c0032" > code
cd ..
git init
git add .
git commit -m "-"
cd ..
LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 DAPP_TEST_NUMBER=9006820 hevm dapp-test --state="state/" --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "test_canAddMkrAuth" --verbose 1

# LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 DAPP_TEST_NUMBER=9006820 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "test_canRemoveOwner" # --verbose 1

# LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 DAPP_TEST_NUMBER=9006820 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "testFail_cannotDealFlop" # --verbose 1
# LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 DAPP_TEST_NUMBER=9006820 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "test_canDealFlop_stuck" # --verbose 1
# LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 DAPP_TEST_NUMBER=9006820 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "test_canDealFlop_new" # --verbose 1

# LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 DAPP_TEST_NUMBER=9006820 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "testFail_cannotDealFlap" # --verbose 1
# LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 DAPP_TEST_NUMBER=9006820 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "test_canDealFlap_stuck" # --verbose 1
# LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 DAPP_TEST_NUMBER=9006820 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "test_canDealFlap_new"  # --verbose 1

# LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 DAPP_TEST_NUMBER=9006820 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "testFail_cannotYankFlop" # --verbose 1
# LANG=C.UTF-8 DAPP_TEST_ADDRESS=0x8EE7D9235e01e6B42345120b5d270bdB763624C7 DAPP_TEST_NUMBER=9006820 hevm dapp-test --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json --dapp-root=. --match "test_canYankFlop" # --verbose 1
