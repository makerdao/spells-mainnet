# spells-mainnet
![Build Status](https://github.com/makerdao/spells-mainnet/actions/workflows/.github/workflows/tests.yaml/badge.svg?branch=master)

Staging repo for MakerDAO executive spells.

## Instructions

### Getting Started

```bash
$ git clone git@github.com:makerdao/spells-mainnet.git
$ dapp update
```

### Build

```bash
$ make
```

### Test (DappTools without Optimizations)

Set `ETH_RPC_URL` to a Mainnet node.

```bash
$ export ETH_RPC_URL=<Mainnet URL>
$ make test
```

### Test (Forge without Optimizations)

#### Prerequisites
1. [Install](https://www.rust-lang.org/tools/install) Rust.
2. [Install](https://github.com/gakonst/foundry#forge) Forge.

#### Operation
Set `ETH_RPC_URL` to a Mainnet node.

```bash
$ export ETH_RPC_URL=<Mainnet URL>
$ make test-forge
```

### Deploy

Set `ETH_RPC_URL` to a Mainnet node and ensure `ETH_GAS_LIMIT` is set to a high enough number to deploy the contract.

```bash
$ export ETH_RPC_URL=<Mainnet URL>
$ export ETH_GAS_LIMIT=5000000
$ export ETH_GAS_PRICE=$(seth --to-wei 100 "gwei")
$ make deploy
```

A few helpful tips to estimate gas.  You can use the following to get a
gas estimate for the deploy.

```bash
make all
make estimate
```

Once you have that, add another million gas as a buffer against
out-of-gas errors.  Set ETH_GAS_LIMIT to this value.

```bash
export ETH_GAS_LIMIT="$((<value from previous step> + 0))"
export ETH_GAS_LIMIT=$(bc <<< "$ETH_GAS_LIMIT + 1000000")
```

You should also check current gas prices on your favorite site
(e.g. https://ethgasstation.info/) and put that gwei value in the
ETH_GAS_PRICE line.

```bash
export ETH_GAS_PRICE=$(seth --to-wei 420 "gwei")
```

### Cast to tenderly

1. Create Tenderly account (no trial period needed atm) https://dashboard.tenderly.co/register
    - Note down `TENDERLY_USER` and `TENDERLY_PROJECT` values
2. Create Tenderly access token https://dashboard.tenderly.co/account/authorization
    - Note down `TENDERLY_ACCESS_KEY` values
3. Export env vars specified above or create `scripts/cast-on-tenderly/.env` file with them
4. Execute `make cast-on-tenderly spell=0x...`, with the address of the spell that hasn't been casted yet
    - The execution should finish with `successfully casted`
5. Open the `publicly sharable transaction url` printed into the console (it should require no credentials)
