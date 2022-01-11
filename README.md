# spells-mainnet
![Build Status](https://github.com/makerdao/spells-mainnet/actions/workflows/.github/workflows/tests.yaml/badge.svg?branch=master)

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

### Adding Collaterals to the System

If the weekly executive needs to onboard a new collateral:

1. Update the `onboardNewCollaterals()` function in `DssSpellCollateralOnboarding.sol`.
2. Update the values in `src/tests/collaterals.sol`
3. uncomment the `onboardNewCollaterals();` in the `actions()` function in `DssSpellAction`

### Test (DappTools with Optimizations)

Set `ETH_RPC_URL` to a Mainnet node.

```
$ export ETH_RPC_URL=<Mainnet URL>
$ make test
```

### Test (Forge without Optimizations)

#### Prerequisites
1. [Install](https://www.rust-lang.org/tools/install) Rust.
2. [Install](https://github.com/gakonst/foundry#forge) Forge.

#### Operation
Set `ETH_RPC_URL` to a Mainnet node.

```
$ export ETH_RPC_URL=<Mainnet URL>
$ make test-forge
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
gas estimate for the deploy.

```
make all
make estimate
```

Once you have that, add another million gas as a buffer against
out-of-gas errors.  Set ETH_GAS to this value.

```
export ETH_GAS="$((<value from previous step> + 0))"
export ETH_GAS=$(bc <<< "$ETH_GAS + 1000000")
```

You should also check current gas prices on your favorite site
(e.g. https://ethgasstation.info/) and put that gwei value in the
ETH_GAS_PRICE line.

```
export ETH_GAS_PRICE=$(seth --to-wei 420 "gwei")
```

#### Verifying spells on etherscan

The process of verifying code on etherscan is a little bit more involved because of `solc`'s weird behaviour around ABI Encoder v2.

1. Run `make flatten`
2. If your spell didn't use `DssExecLib.addNewCollateral` you need to tweak the flattened source.
   1. Remove `pragma experimental ABIEncoderV2;`
   2. Comment out `DssExecLib.addNewCollateral` method.
3. Go to etherscan and verify source.
   1. Add library: `DssExecLib:0xfD88CeE74f7D78697775aBDAE53f9Da1559728E4`
   2. Ensure optimizer is on and optimize runs = 1
