# Description

# Contribution Checklist

- [ ] PR title ends with `(SC-<TICKET_NUMBER>)`
- [ ] Link to clubhouse ticket
- [ ] Code approved
- [ ] Tests approved
- [ ] CI Tests pass

# Checklist

- [ ] Every contract variable/method declared as public/external private/internal
- [ ] Consider if this PR needs the `officeHours` modifier
- [ ] Verify expiration (`4 days + 2 hours` monthly and `30 days` for the rest)
- [ ] Verify hash in the description matches [here](https://emn178.github.io/online-tools/keccak_256.html)
- [ ] Validate all addresses used are in changelog or known
- [ ] Deploy spell `ETH_GAS="XXX" ETH_GAS_PRICE="YYY" make deploy`
- [ ] Verify `mainnet` contract on etherscan
- [ ] Change test to use mainnet spell address and deploy timestamp
- [ ] Keep `DssSpell.sol` and `DssSpell.t.sol` the same, but make a copy in `archive`
- [ ] `squash and merge` this PR
