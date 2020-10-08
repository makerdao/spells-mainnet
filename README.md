# spells-mainnet

Staging repo for MakerDAO weekly executive spells.

### Getting Started

```
$ git clone git@github.com:makerdao/spells-mainnet.git
$ dapp update
```

### Build

```
$ make
```

### Test

Set `ETH_RPC_URL` to a Mainnet node.

```
$ export ETH_RPC_URL=<Mainnet URL>
$ make test
```

### Deploy

Set `ETH_RPC_URL` to a Mainnet node and ensure `ETH_GAS` is set to a high enough number to deploy the contract.

```
$ export ETH_RPC_URL=<Mainnet URL>
$ export ETH_GAS=4000000
$ SOLC_FLAGS="--optimize --optimize-runs=1" dapp --use solc:0.5.12 build && dapp create DssSpell --gas=2000000 --gas-price="$(seth --to-wei 420 "gwei")"

```
