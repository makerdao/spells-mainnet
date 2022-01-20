# Description

# Contribution Checklist

- [ ] PR title starts with `(PE-<TICKET_NUMBER>)`
- [ ] Code approved
- [ ] Tests approved
- [ ] CI Tests pass

# Checklist

- [ ] Every contract variable/method declared as public/external private/internal
- [ ] Consider if this PR needs the `officeHours` modifier override
- [ ] Verify expiration (`30 days` unless otherwise specified)
- [ ] Verify hash in the description matches [here](https://emn178.github.io/online-tools/keccak_256.html)
- [ ] Validate all addresses used are in changelog or known
- [ ] Notify any external teams affected by the spell so they have the opportunity to review
- [ ] Deploy spell `ETH_GAS="XXX" ETH_GAS_PRICE="YYY" make deploy`
- [ ] Verify `mainnet` contract on etherscan
- [ ] Change test to use mainnet spell address and deploy timestamp
- [ ] Run `make archive-spell` or `make date="YYYY-MM-DD" archive-spell` to make an archive directory and copy `DssSpell.sol`, `DssSpell.t.sol`, `DssSpell.t.base.sol`, and `DssSpellCollateralOnboarding.sol`
- [ ] `squash and merge` this PR
