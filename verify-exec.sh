#!/usr/bin/env bash
### verify-exec -- verify contract souce on etherscan
### Usage: verify-exec <path>:<contractname> <address> [constructorArgs]

set -e

[[ $ETHERSCAN_API_KEY ]] || {
  cat >&2 <<.
  You need an Etherscan Api Key to verify contracts.
  Create one at https://etherscan.io/myapikey
  Then export it with \`export ETHERSCAN_API_KEY=xxxxxxxx'
.
  exit 1
}

[[ $1 ]] || (verify-exec --help >&2 && exit 1)
[[ $2 ]] || (verify-exec --help >&2 && exit 1)

chain=$(seth chain)
case "$chain" in
  ethlive|mainnet)
    export ETHERSCAN_API_URL=https://api.etherscan.io/api
    export ETHERSCAN_URL=https://etherscan.io/address
    ;;
  ropsten|kovan|rinkeby|goerli)
    export ETHERSCAN_API_URL=https://api-$chain.etherscan.io/api
    export ETHERSCAN_URL=https://$chain.etherscan.io/address
    ;;
  *)
    echo >&2 "Verification only works on mainnet, ropsten, kovan, rinkeby, and goerli."
    exit 1
esac

path=${1?contractname}
name=${path#*:}
address=${2?contractaddress}

meta=$(jshon <<<"$contract" -e metadata -u)
version=$(jshon <<<"$meta" -e compiler -e version -u)
optimized=$(jshon <<<"$meta" -e settings -e optimizer -e enabled -u)
runs=$(jshon <<<"$meta" -e settings -e optimizer -e runs -u)

abi=$(jq '.["abi"]' -r <<< "$contract")
type=$(seth --abi-constructor <<< "$abi")
constructor=${type/constructor/${1#*:}}

if [[ $3 ]]; then
    constructorArguments=$(seth calldata "$constructor" "${@:3}")
    constructorArguments=${constructorArguments#0x}
    constructorArguments=${constructorArguments:8}
fi


# Etherscan requires leading 'v' which isn't in the artifacts
version="v${version}"

# Get the list of supported solc versions and compare
# Etherscan uses the js solc, which is not guaranteed to match the C distribution signature

version_list=$(curl -fsS "https://raw.githubusercontent.com/ethereum/solc-bin/gh-pages/bin/list.txt")
# There have been a couple of instances where the solc js release used by
#   Etherscan does not match the tag of the C distributions.
if [[ $version_list != *"$version"* ]]; then
  regex="(.+commit+.)"
  # Version incompatible with js release
  echo "Compiler version $version is not compatible with etherscan"
  if [[ $version =~ $regex ]]; then
    version_proto=${BASH_REMATCH[1]}
    version=$(echo "$version_list" | grep -o "${version_proto}\{8\}")
    echo "Attempting ${version}"
  fi
fi


if [[ "$optimized" = "true" ]]; then
  optimized=1
else
  optimized=0
fi

# Standard Input JSON

inputJSON=$(dapp mk-standard-json)

params=(
  "module=contract" "action=verifysourcecode"
  "contractname=$name" "contractaddress=$address"
  "sourcecode=$inputJSON" "codeformat=solidity-standard-json-input"
  "optimizationUsed=$optimized" "runs=$runs"
  "apikey=$ETHERSCAN_API_KEY"
)

query=$(printf "&%s" "${params[@]}")

count=0
while [ $count -lt 5 ]; do
  sleep 10

  response=$(curl -fsS "$ETHERSCAN_API_URL" -d "$query" \
  --data-urlencode "compilerversion=$version" \
  --data-urlencode "constructorArguements=$constructorArguments" -X POST)
  # NOTE: the Arguements typo is in etherscan's API

  status=$(jshon <<<"$response" -e status -u)
  guid=$(jshon <<<"$response" -e result -u)
  message=$(jshon <<<"$response" -e message -u)
  count=$((count + 1))

  [[ $status = 1 ]] && break;
done

[[ $status = 0 && $message = "Contract source code already verified" ]] && {
  echo >&2 "Contract source code already verified."
  echo >&2 "Go to $ETHERSCAN_URL/$2#code"
  exit 0
}

[[ $status = 0 ]] && {
  echo >&2 "There was an error verifying this contract."
  echo >&2 "Response: $message"
  echo >&2 "Details: $guid"
  exit 1
}

[[ $DAPP_ASYNC == yes ]] && exit

sleep 20
response=$(curl -fsS "$ETHERSCAN_API_URL" \
-d "module=contract&action=checkverifystatus&guid=$guid&apikey=$ETHERSCAN_API_KEY")

status=$(jshon <<<"$response" -e status -u)
result=$(jshon <<<"$response" -e result -u)

[[ $status = 1 ]] && {
  echo >&2 "$result"
  echo >&2 "Go to $ETHERSCAN_URL/$2#code"
  exit 0
}

[[ $status = 0 ]] && {
  echo >&2 "Failure"
  echo >&2 "$result"
  exit 1
}
