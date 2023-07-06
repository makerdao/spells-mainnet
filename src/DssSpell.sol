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

interface RwaOutputConduitLike {
    function deny(address usr) external;
    function hope(address usr) external;
    function nope(address usr) external;
    function mate(address usr) external;
    function hate(address usr) external;
    function kiss(address who) external;
    function diss(address who) external;
    function file(bytes32 what, address data) external;
    function clap(address _psm) external;
}

interface RwaUrnLike {
    function file(bytes32 what, address data) external;
}

interface ChainlogLike {
    function removeAddress(bytes32) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/e4bf988dd35f82e2828e1ce02c6762ddd398ff92/governance/votes/Executive%20vote%20-%20June%2028%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-07-12 MakerDAO Executive Spell | Hash: TODO";

    address internal immutable RWA015_A_URN                 = DssExecLib.getChangelogAddress("RWA015_A_URN");
    address internal immutable RWA015_A_OUTPUT_CONDUIT_PAX  = DssExecLib.getChangelogAddress("RWA015_A_OUTPUT_CONDUIT");
    address internal immutable RWA015_A_OUTPUT_CONDUIT_USDC = DssExecLib.getChangelogAddress("RWA015_A_OUTPUT_CONDUIT_LEGACY");
    address internal immutable MCD_PSM_PAX_A                = DssExecLib.getChangelogAddress("MCD_PSM_PAX_A");
    address internal immutable MCD_PSM_GUSD_A               = DssExecLib.getChangelogAddress("MCD_PSM_GUSD_A");
    address internal immutable MCD_PSM_USDC_A               = DssExecLib.getChangelogAddress("MCD_PSM_USDC_A");
    address internal immutable MCD_ESM                      = DssExecLib.esm();

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
    }

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

    // Operator address
    address internal constant RWA015_A_OPERATOR            = 0x23a10f09Fac6CCDbfb6d9f0215C795F9591D7476;
    // Custody address
    address internal constant RWA015_A_CUSTODY             = 0x65729807485F6f7695AF863d97D62140B7d69d83;
    address internal constant RWA015_A_OUTPUT_CONDUIT      = 0x1E86CB085f249772f7e7443631a87c6BDba2aCEb;

    function actions() public override {
        // ----- Deploy Multiswap Conduit for RWA015-A -----

        // OPERATOR permission on RWA015_A_OUTPUT_CONDUIT
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).hope(RWA015_A_OPERATOR);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).mate(RWA015_A_OPERATOR);
        // Custody whitelist for output conduit destination address
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).kiss(RWA015_A_CUSTODY);
        // Whitelist PSM's
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).clap(MCD_PSM_PAX_A);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).clap(MCD_PSM_GUSD_A);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).clap(MCD_PSM_USDC_A);
        // Set "quitTo" address for RWA015_A_OUTPUT_CONDUIT
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).file("quitTo", RWA015_A_URN);
        // Route URN to new conduit
        RwaUrnLike(RWA015_A_URN).file("outputConduit", RWA015_A_OUTPUT_CONDUIT);
        // Additional ESM authorization
        DssExecLib.authorize(RWA015_A_OUTPUT_CONDUIT, MCD_ESM);

        DssExecLib.setChangelogAddress("RWA015_A_OUTPUT_CONDUIT", RWA015_A_OUTPUT_CONDUIT);

        // Unwind Permissions from old Conduits and remove them from Chainlog

        // Revoke permissions on RWA015_A_OUTPUT_CONDUIT_PAX
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_PAX).nope(RWA015_A_OPERATOR);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_PAX).hate(RWA015_A_OPERATOR);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_PAX).diss(RWA015_A_CUSTODY);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_PAX).file("quitTo", address(0));
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_PAX).deny(MCD_ESM);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_PAX).deny(address(this));

        // Revoke permissions on RWA015_A_OUTPUT_CONDUIT_USDC
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_USDC).nope(RWA015_A_OPERATOR);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_USDC).hate(RWA015_A_OPERATOR);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_USDC).diss(RWA015_A_CUSTODY);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_USDC).file("quitTo", address(0));
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_USDC).deny(MCD_ESM);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_USDC).deny(address(this));

        // Remove Legacy Conduit From Chainlog
        ChainlogLike(DssExecLib.LOG).removeAddress("RWA015_A_OUTPUT_CONDUIT_LEGACY");

        // ----- Deploy FlapperUniV2 -----

        // ----- Scope Defined Parameter Changes -----

        // ----- Delegate Compensation for June 2023 -----

        // ----- CRVV1ETHSTETH-A 1st Stage Offboarding -----

        // ----- Ecosystem Actor Dai Budget Stream -----

        // ----- Ecosystem Actor MKR Budget Stream -----
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
