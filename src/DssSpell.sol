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
import { MCD, DssInstance } from "dss-test/MCD.sol";
import { FlapperInit, FlapperInstance, FlapperUniV2Config } from "src/dependencies/dss-flappers/FlapperInit.sol";

interface DssCronSequencerLike {
    function addJob(address) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/e4bf988dd35f82e2828e1ce02c6762ddd398ff92/governance/votes/Executive%20vote%20-%20June%2028%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-07-12 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
    }

    uint256 internal constant THOUSAND    = 10 **  3;
    uint256 internal constant MILLION     = 10 **  6;
    uint256 internal constant WAD         = 10 ** 18;
    uint256 internal constant RAD         = 10 ** 45;

    address internal constant MCD_FLAP    = 0x0c10Ae443cCB4604435Ba63DA80CCc63311615Bc;
    address internal constant FLAPPER_MOM = 0xee2058A11612587Ef6F5470e7776ceB0E4736078;
    address internal constant PIP_MKR     = 0xdbBe5e9B1dAa91430cF0772fCEbe53F6c6f137DF;

    address internal constant CRON_SEQUENCER       = 0x238b4E35dAed6100C6162fAE4510261f88996EC9;
    address internal constant CRON_AUTOLINE_JOB    = 0x67AD4000e73579B9725eE3A149F85C4Af0A61361;
    address internal constant CRON_LERP_JOB        = 0x8F8f2FC1F0380B9Ff4fE5c3142d0811aC89E32fB;
    address internal constant CRON_D3M_JOB         = 0x1Bb799509b0B039345f910dfFb71eEfAc7022323;
    address internal constant CRON_CLIPPER_MOM_JOB = 0xc3A76B34CFBdA7A3a5215629a0B937CBDEC7C71a;
    address internal constant CRON_ORACLE_JOB      = 0xe717Ec34b2707fc8c226b34be5eae8482d06ED03;
    address internal constant CRON_FLAP_JOB        = 0xc32506E9bB590971671b649d9B8e18CB6260559F;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // uint256 internal constant X_PCT_RATE      = ;

    function actions() public override {
        // ----- Deploy Multiswap Conduit for RWA015-A -----

        // ----- Add Cron Jobs to Chainlog -----
        // Forum: https://forum.makerdao.com/t/dsscron-housekeeping-additions/21292

        DssExecLib.setChangelogAddress("CRON_SEQUENCER",       CRON_SEQUENCER);
        DssExecLib.setChangelogAddress("CRON_AUTOLINE_JOB",    CRON_AUTOLINE_JOB);
        DssExecLib.setChangelogAddress("CRON_LERP_JOB",        CRON_LERP_JOB);
        DssExecLib.setChangelogAddress("CRON_D3M_JOB",         CRON_D3M_JOB);
        DssExecLib.setChangelogAddress("CRON_CLIPPER_MOM_JOB", CRON_CLIPPER_MOM_JOB);
        DssExecLib.setChangelogAddress("CRON_ORACLE_JOB",      CRON_ORACLE_JOB);

        // ----- Deploy FlapperUniV2 -----
        // https://vote.makerdao.com/polling/QmQmxEZp#poll-detail
        // dss-flappers @ b10f68224c648166cd4f9b09595412bce9824301

        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);
        FlapperInstance memory flap = FlapperInstance({
            flapper: MCD_FLAP,
            mom:     FLAPPER_MOM
        });
        FlapperUniV2Config memory cfg = FlapperUniV2Config({
            hop:  1577 seconds,
            want: 98 * WAD / 100,
            pip:  PIP_MKR,
            hump: 50 * MILLION * RAD,
            bump: 5 * THOUSAND * RAD
        });

        FlapperInit.initFlapperUniV2({
            dss: dss,
            flapperInstance: flap,
            cfg: cfg
        });

        FlapperInit.initDirectOracle({
            flapper : MCD_FLAP
        });

        DssExecLib.setChangelogAddress("PIP_MKR", PIP_MKR);

        DssCronSequencerLike(CRON_SEQUENCER).addJob(CRON_FLAP_JOB);
        DssExecLib.setChangelogAddress("CRON_FLAP_JOB", CRON_FLAP_JOB);

        // ----- Scope Defined Parameter Changes -----

        // ----- Delegate Compensation for June 2023 -----

        // ----- CRVV1ETHSTETH-A 1st Stage Offboarding -----

        // ----- Ecosystem Actor Dai Budget Stream -----

        // ----- Ecosystem Actor MKR Budget Stream -----

        // ----- Update ChainLog version -----

        DssExecLib.setChangelogVersion("1.15.0");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
