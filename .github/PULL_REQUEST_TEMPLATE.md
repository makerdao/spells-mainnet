# Description

# Contribution Checklist

- [ ] First commit title starts with 'SC-**TICKET_NUMBER**:'
- [ ] Link to clubhouse ticket
- [ ] Code approved
- [ ] Tests approved
- [ ] CI Tests pass

# Checklist

- [ ] Every contract variable/method declared as public/external private/internal
- [ ] Consider if this PR needs the `officeHours` modifier
- [ ] Validate all addresses used are in changelog or known
- [ ] Deploy spell `SOLC_FLAGS="--optimize --optimize-runs=1" dapp --use solc:0.5.12 build && dapp create DssSpell --gas=2000000 --gas-price="$(seth --to-wei 420 "gwei")"`
- [ ] Verify `mainnet` contract on etherscan
- [ ] Change test to use mainnet spell address and deploy timestamp
- [ ] Keep `DssSpell.sol` and `DssSpell.t.sol` the same, but make a copy in `archive`
- [ ] `squash and merge` this PR
