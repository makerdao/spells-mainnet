// SPDX-FileCopyrightText: © 2020 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.16;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";
import { GemAbstract } from "dss-interfaces/ERC/GemAbstract.sol";

interface DssCronSequencerLike {
    function addJob(address job) external;
    function removeJob(address job) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description =
        "TODO MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // ---------- Rates ----------
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // uint256 internal constant X_PCT_1000000003022265980097387650RATE = ;
    uint256 internal constant EIGHT_PT_TWO_FIVE_PCT_RATE    = 1000000002513736079215619839;
    uint256 internal constant EIGHT_PT_SEVEN_FIVE_PCT_RATE  = 1000000002659864411854984565;
    uint256 internal constant EIGHT_PCT_RATE                = 1000000002440418608258400030;
    uint256 internal constant NINE_PT_TWO_FIVE_PCT_RATE     = 1000000002805322428706865331;
    uint256 internal constant NINE_PCT_RATE                 = 1000000002732676825177582095;
    uint256 internal constant NINE_PT_SEVEN_FIVE_PCT_RATE   = 1000000002950116251408586949;
    uint256 internal constant TEN_PT_TWO_FIVE_PCT_RATE      = 1000000003094251918120023627;
    uint256 internal constant NINE_PT_FIVE_PCT_RATE         = 1000000002877801985002875644;

    // ---------- Contract addresses ----------
    GemAbstract internal immutable MKR = GemAbstract(DssExecLib.mkr());

    // ---------- Dss-Cron Update ----------
    address internal immutable CRON_SEQUENCER               = DssExecLib.getChangelogAddress("CRON_SEQUENCER");
    address internal immutable CRON_D3M_JOB                 = DssExecLib.getChangelogAddress("CRON_D3M_JOB");
    address internal constant CRON_D3M_JOB_NEW              = 0x2Ea4aDE144485895B923466B4521F5ebC03a0AeF;

    // ---------- Launch Funding Transfers ----------
    address internal constant LAUNCH_PROJECT_FUNDING        = 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F;

    // ---------- Bug Bounty Payouts ----------
    address internal constant IMMUNEFI_BOUNTY_PAYOUT_WALLET = 0x7119f398b6C06095c6E8964C1f58e7C1BAa79E18;
    address internal constant BUG_BOUNTY_PAYOUT_WALLET      = 0xa24EC79bdF03bB325F36878573B13AedFEd0717f;

    function actions() public override {
        // ---------- Dss-Cron Update ----------

        // Update D3MJob in the sequencer (0x238b4E35dAed6100C6162fAE4510261f88996EC9)

        // sequencer.removeJob(0x1Bb799509b0B039345f910dfFb71eEfAc7022323);
        DssCronSequencerLike(CRON_SEQUENCER).removeJob(CRON_D3M_JOB);

        // sequencer.addJob(0x2Ea4aDE144485895B923466B4521F5ebC03a0AeF);
        DssCronSequencerLike(CRON_SEQUENCER).addJob(CRON_D3M_JOB_NEW);

        // Note: update CRON_D3M_JOB address in the chainlog
        DssExecLib.setChangelogAddress("CRON_D3M_JOB", CRON_D3M_JOB_NEW);

        // ---------- Launch Funding Transfers ----------
        // Forum: https://forum.makerdao.com/t/utilization-of-the-launch-project-under-the-accessibility-scope/21468/16
        // MIP: https://mips.makerdao.com/mips/details/MIP108#9-1-launch-project-budget

        // Launch Project - 5358006.99 DAI - 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        DssExecLib.sendPaymentFromSurplusBuffer(LAUNCH_PROJECT_FUNDING, 5_358_007); // TODO value

        // Launch Project - 1969.17 MKR - 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        MKR.transfer(LAUNCH_PROJECT_FUNDING, 1969.17 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // ---------- Bug Bounty Payouts ----------
        // Forum: https://forum.makerdao.com/t/bounty-payout-request-for-immunefi-bug-29806/24240

        // Immunefi Bounty - 5000 DAI - 0x7119f398b6C06095c6E8964C1f58e7C1BAa79E18
        DssExecLib.sendPaymentFromSurplusBuffer(IMMUNEFI_BOUNTY_PAYOUT_WALLET, 5_000);

        // Bug Bounty  - 50000 DAI - 0xa24EC79bdF03bB325F36878573B13AedFEd0717f
        DssExecLib.sendPaymentFromSurplusBuffer(BUG_BOUNTY_PAYOUT_WALLET, 50_000);

        // ---------- Stability Scope Parameter Changes ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-13-under-sta-article-3-3/24250

        // ETH-A: Decrease the Stability Fee by 2 percentage points from 10.25% to 8.25%
        DssExecLib.setIlkStabilityFee("ETH-A", EIGHT_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // ETH-B: Decrease the Stability Fee by 2 percentage points from 10.75% to 8.75%
        DssExecLib.setIlkStabilityFee("ETH-B", EIGHT_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // ETH-C: Decrease the Stability Fee by 2 percentage points from 10.00% to 8.00%
        DssExecLib.setIlkStabilityFee("ETH-C", EIGHT_PCT_RATE, /* doDrip = */ true);

        // WSTETH-A: Decrease the Stability Fee by 2 percentage points from 11.25% to 9.25%
        DssExecLib.setIlkStabilityFee("WSTETH-A", NINE_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // WSTETH-B: Decrease the Stability Fee by 2 percentage points from 11.00% to 9.00%
        DssExecLib.setIlkStabilityFee("WSTETH-B", NINE_PCT_RATE, /* doDrip = */ true);

        // WBTC-A: Decrease the Stability Fee by 2 percentage points from 11.75% to 9.75%
        DssExecLib.setIlkStabilityFee("WBTC-A", NINE_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // WBTC-B: Decrease the Stability Fee by 2 percentage points from 12.25% to 10.25%
        DssExecLib.setIlkStabilityFee("WBTC-B", TEN_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // WBTC-C: Decrease the Stability Fee by 2 percentage points from 11.50% to 9.50%
        DssExecLib.setIlkStabilityFee("WBTC-C", NINE_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // DSR: Decrease the Dai Savings Rate by 2 percentage points from 10.00% to 8.00%
        DssExecLib.setDSR(EIGHT_PCT_RATE, /* doDrip = */ true);

        // Note: bump chainlog version due to the updated CRON_D3M_JOB address
        DssExecLib.setChangelogVersion("1.17.4");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
