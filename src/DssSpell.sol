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

    uint256 internal constant THREE_PT_ONE_NINE_PCT_RATE  = 1000000000995743377573746041;
    uint256 internal constant THREE_PT_FOUR_FOUR_PCT_RATE = 1000000001072474267302354182;
    uint256 internal constant THREE_PT_NINE_FOUR_PCT_RATE = 1000000001225381266358479708;
    uint256 internal constant FIVE_PT_SIX_NINE_PCT_RATE   = 1000000001754822903403114680;
    uint256 internal constant SIX_PT_ONE_NINE_PCT_RATE    = 1000000001904482384730282575;
    uint256 internal constant FIVE_PT_FOUR_FOUR_PCT_RATE  = 1000000001679727448331902751;

    function actions() public override {
        // ----- Deploy Multiswap Conduit for RWA015-A -----

        // ----- Deploy FlapperUniV2 -----

        // ----- Scope Defined Parameter Changes -----
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-3/21238/6

        // Reduce DSR by 0.30% from 3.49% to 3.19%
        DssExecLib.setDSR(THREE_PT_ONE_NINE_PCT_RATE, /* doDrip = */ true);

        // Reduce WSTETH-A Liquidation Ratio by 10% from 160% to 150%
        DssExecLib.setIlkLiquidationRatio("WSTETH-A", 150_00);

        // Reduce WSTETH-B Liquidation Ratio by 10% from 185% to 175%
        DssExecLib.setIlkLiquidationRatio("WSTETH-B", 175_00);

        // Reduce RETH-A Liquidation Ratio by 20% from 170% to 150%
        DssExecLib.setIlkLiquidationRatio("RETH-A", 150_00);

        // Reduce the ETH-A Stability Fee (SF) by 0.30% from 3.74% to 3.44%
        DssExecLib.setIlkStabilityFee("ETH-A", THREE_PT_FOUR_FOUR_PCT_RATE, /* doDrip = */ true);

        // Reduce the ETH-B Stability Fee (SF) by 0.30% from 4.24% to 3.94%
        DssExecLib.setIlkStabilityFee("ETH-B", THREE_PT_NINE_FOUR_PCT_RATE, /* doDrip = */ true);

        // Reduce the ETH-C Stability Fee (SF) by 0.30% from 3.49% to 3.19%
        DssExecLib.setIlkStabilityFee("ETH-C", THREE_PT_ONE_NINE_PCT_RATE, /* doDrip = */ true);

        // Reduce the WSTETH-A Stability Fee (SF) by 0.30% from 3.74% to 3.44%
        DssExecLib.setIlkStabilityFee("WSTETH-A", THREE_PT_FOUR_FOUR_PCT_RATE, /* doDrip = */ true);

        // Reduce the WSTETH-B Stability Fee (SF) by 0.30% from 3.49% to 3.19%
        DssExecLib.setIlkStabilityFee("WSTETH-B", THREE_PT_ONE_NINE_PCT_RATE, /* doDrip = */ true);

        // Reduce the RETH-A Stability Fee (SF) by 0.30% from 3.74% to 3.44%
        DssExecLib.setIlkStabilityFee("RETH-A", THREE_PT_FOUR_FOUR_PCT_RATE, /* doDrip = */ true);

        // Reduce the WBTC-A Stability Fee (SF) by 0.11% from 5.80% to 5.69%
        DssExecLib.setIlkStabilityFee("WBTC-A", FIVE_PT_SIX_NINE_PCT_RATE, /* doDrip = */ true);

        // Reduce the WBTC-B Stability Fee (SF) by 0.11% from 6.30% to 6.19%
        DssExecLib.setIlkStabilityFee("WBTC-B", SIX_PT_ONE_NINE_PCT_RATE, /* doDrip = */ true);

        // Reduce the WBTC-C Stability Fee (SF) by 0.11% from 5.55% to 5.44%
        DssExecLib.setIlkStabilityFee("WBTC-C", FIVE_PT_FOUR_FOUR_PCT_RATE, /* doDrip = */ true);

        // ----- Delegate Compensation for June 2023 -----
        // TODO: add as soon as it's in the exec

        // ----- CRVV1ETHSTETH-A 1st Stage Offboarding -----
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-3/21238/6

        // Set CRVV1ETHSTETH-A Debt Ceiling to 0
        DssExecLib.setIlkDebtCeiling("CRVV1ETHSTETH-A", 0);

        // Remove CRVV1ETHSTETH-A from autoline
        DssExecLib.removeIlkFromAutoLine("CRVV1ETHSTETH-A");

        // ----- Ecosystem Actor Dai Budget Stream -----
        // Poll: https://vote.makerdao.com/polling/QmdnSKPu#poll-detail
        // Forum: https://forum.makerdao.com/t/mip102c2-sp8-mip-amendment-subproposals/20761
        // Mip: https://mips.makerdao.com/mips/details/MIP106#7-4-2-1a-

        // Chronicle Labs Auditor Wallet | 2023-07-01 00:00:00 to 2024-06-30 23:59:59 | 3,721,800 DAI | 0x68D0ca2d5Ac777F6A9b0d1be44332BB3d5981C2f
        // TODO: add

        // ----- Ecosystem Actor MKR Budget Stream -----
        // Poll: https://vote.makerdao.com/polling/QmdnSKPu#poll-detail
        // Forum: https://forum.makerdao.com/t/mip102c2-sp8-mip-amendment-subproposals/20761
        // Mip: https://mips.makerdao.com/mips/details/MIP106#7-4-2-1a-

        // Chronicle Labs Auditor Wallet | 2023-07-01 00:00:00 to 2024-06-30 23:59:59 | 2,216.4 MKR | 0x68D0ca2d5Ac777F6A9b0d1be44332BB3d5981C2f
        // TODO: add

        // ----- Core Unit MKR Vesting Transfer -----
        // Mip: https://mips.makerdao.com/mips/details/MIP40c3SP36#mkr-vesting

        // DECO-001 - 125 MKR - 0xF482D1031E5b172D42B2DAA1b6e5Cbf6519596f7
        // TODO: add
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
