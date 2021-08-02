# Description

# Contribution Checklist

- [ ] PR title starts with `(PE-<TICKET_NUMBER>)`
- [ ] Link to clubhouse ticket
- [ ] Code approved
- [ ] Tests approved
- [ ] CI Tests pass

# Checklist

- [ ] Every contract variable/method declared as public/external private/internal
- [ ] Consider if this PR needs the `officeHours` modifier
- [ ] Verify expiration (`4 days` monthly and `30 days` for the rest)
- [ ] Verify hash in the description matches [here](https://emn178.github.io/online-tools/keccak_256.html)
- [ ] Validate all addresses used are in changelog or known
- [ ] Notify any external teams affected by the spell so they have the opportunity to review
- [ ] Deploy spell `ETH_GAS="XXX" ETH_GAS_PRICE="YYY" make deploy`
- [ ] Verify `mainnet` contract on etherscan
- [ ] Change test to use mainnet spell address and deploy timestamp
- [ ] Keep `DssSpell.sol` and `DssSpell.t.sol` the same, but make a copy in `archive`
- [ ] `squash and merge` this PR
