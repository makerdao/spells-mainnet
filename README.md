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
$ export ETH_GAS=5000000
$ export ETH_GAS_PRICE=$(seth --to-wei 100 "gwei")
$ make deploy
```

A few helpful tips to estimate gas.  You can use the following to get a
gas estimate for the deploy.  Once you have that, add another million gas
as a buffer against out-of-gas errors.  Feed this value back into ETH_GAS.

```
SOLC_FLAGS="--optimize --optimize-runs=1" dapp --use solc:0.5.12 build --extract
seth estimate --create $(cat ./out/DssSpell.bin) 'DssSpell()'
export ETH_GAS="$(($ETH_GAS + 0))"
export ETH_GAS=$(bc <<< "$ETH_GAS + 1000000")
```

You should also check current gas prices on your favorite site
(e.g. https://ethgasstation.info/) and put that gwei value in the
ETH_GAS_PRICE line.

```
export ETH_GAS_PRICE=$(seth --to-wei 420 "gwei")
```
