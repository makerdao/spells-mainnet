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

pragma solidity 0.6.12;
// Enable ABIEncoderV2 when onboarding collateral through `DssExecLib.addNewCollateral()`
// pragma experimental ABIEncoderV2;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

interface StarknetGovRelayLike {
    function relay(uint256 spell) external;
}

interface OracleLiftLike {
    function lift(address[] calldata) external;
}

interface TokenLike {
    function transfer(address, uint256) external returns (bool);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/d8c711404e9e17db24b611aa03d45507c1993148/governance/votes/Executive%20vote%20-%20November%2016%2C%202022.md -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-11-30 MakerDAO Executive Spell | Hash: TODO";

    address constant internal MCD_CLIP_CALC_GUSD_A = 0xC287E4e9017259f3b21C86A0Ef7840243eC3f4d6;
    address constant internal MCD_CLIP_CALC_USDC_A = 0x00A0F90666c6Cd3E615cF8459A47e89A08817602;
    address constant internal MCD_CLIP_CALC_PAXUSD_A = 0xA2a4aeFEd398661B0a873d3782DA121c194a0201;

    address constant internal RETH_ORACLE = 0xF86360f0127f8A441Cfca332c75992D1C692b3D1;
    address constant internal RETH_LIGHTFEED = 0xa580BBCB1Cee2BCec4De2Ea870D20a12A964819e;

    address immutable internal STARKNET_GOV_RELAY = DssExecLib.getChangelogAddress("STARKNET_GOV_RELAY");
    address constant internal NEW_STARKNET_GOV_RELAY = 0x2385C60D2756Ed8CA001817fC37FDa216d7466c0;
    uint256 constant internal L2_GOV_RELAY_SPELL = 0x013c117c7bdb9dbbb45813fd6de8e301bbceed2cfad7c4c589cafa4478104672;

    address constant internal DUX_WALLET = 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //

    function actions() public override {
        // ----------------- Compound v2 D3M Onboarding -----------------
        // https://vote.makerdao.com/polling/QmWYfgY2#poll-detail

        // ----------------- Offboard GUSD-A, USDC-A and USDP-A -----------------
        // Poll: https://vote.makerdao.com/polling/QmZbsHqu#poll-detail
        // Forum: https://forum.makerdao.com/t/usdc-a-usdp-a-gusd-a-liquidation-parameters-auctions-activation/18744
        {
            bytes32 _ilk  = bytes32("GUSD-A");
            address _clip = DssExecLib.getChangelogAddress("MCD_CLIP_GUSD_A");
            //
            // Enable liquidations for GUSD-A
            // Note: ClipperMom cannot circuit-break on a DS-Value but we're adding
            //       the rely for consistency with other collaterals and in case the PIP
            //       changes to an OSM.
            DssExecLib.authorize(_clip, DssExecLib.clipperMom());
            DssExecLib.setValue(_clip, "stopped", 0);
            // Use Abacus/LinearDecrease
            DssExecLib.setContract(_clip, "calc", MCD_CLIP_CALC_GUSD_A);
            // Set Liquidation Penalty to 0
            DssExecLib.setIlkLiquidationPenalty(_ilk, 0);
            // Set Auction Price Multiplier (buf) to 1
            DssExecLib.setStartingPriceMultiplicativeFactor(_ilk, 100_00);
            // Set Local Liquidation Limit (ilk.hole) to 300k DAI
            DssExecLib.setIlkMaxLiquidationAmount(_ilk, 300_000);
            // Set tau for Abacus/LinearDecrease to 4,320,000 second
            DssExecLib.setLinearDecrease(MCD_CLIP_CALC_GUSD_A, 4_320_000);
            // Set Max Auction Duration (tail) to 43,200 seconds
            DssExecLib.setAuctionTimeBeforeReset(_ilk, 43_200);
            // Set Max Auction Drawdown / Permitted Drop (cusp) to 0.99
            DssExecLib.setAuctionPermittedDrop(_ilk, 99_00);
            // Set Proportional Kick Incentive (chip) to 0
            DssExecLib.setKeeperIncentivePercent(_ilk, 0);
            // Set Flat Kick Incentive (tip) to 0
            DssExecLib.setKeeperIncentiveFlatRate(_ilk, 0);
        }
        {
            bytes32 _ilk  = bytes32("USDC-A");
            address _clip = DssExecLib.getChangelogAddress("MCD_CLIP_USDC_A");
            //
            // Enable liquidations for USDC-A
            // Note: ClipperMom cannot circuit-break on a DS-Value but we're adding
            //       the rely for consistency with other collaterals and in case the PIP
            //       changes to an OSM.
            DssExecLib.authorize(_clip, DssExecLib.clipperMom());
            DssExecLib.setValue(_clip, "stopped", 0);
            // Use Abacus/LinearDecrease
            DssExecLib.setContract(_clip, "calc", MCD_CLIP_CALC_USDC_A);
            // Set Liquidation Penalty to 0
            DssExecLib.setIlkLiquidationPenalty(_ilk, 0);
            // Set Auction Price Multiplier (buf) to 1
            DssExecLib.setStartingPriceMultiplicativeFactor(_ilk, 100_00);
            // Set Local Liquidation Limit (ilk.hole) to 20m DAI
            DssExecLib.setIlkMaxLiquidationAmount(_ilk, 20_000_000);
            // Set tau for Abacus/LinearDecrease to 4,320,000 second
            DssExecLib.setLinearDecrease(MCD_CLIP_CALC_USDC_A, 4_320_000);
            // Set Max Auction Duration (tail) to 43,200 seconds
            DssExecLib.setAuctionTimeBeforeReset(_ilk, 43_200);
            // Set Max Auction Drawdown / Permitted Drop (cusp) to 0.99
            DssExecLib.setAuctionPermittedDrop(_ilk, 99_00);
            // Set Proportional Kick Incentive (chip) to 0
            DssExecLib.setKeeperIncentivePercent(_ilk, 0);
            // Set Flat Kick Incentive (tip) to 0
            DssExecLib.setKeeperIncentiveFlatRate(_ilk, 0);
        }
        {
            bytes32 _ilk  = bytes32("PAXUSD-A");
            address _clip = DssExecLib.getChangelogAddress("MCD_CLIP_PAXUSD_A");
            //
            // Enable liquidations for PAXUSD-A
            // Note: ClipperMom cannot circuit-break on a DS-Value but we're adding
            //       the rely for consistency with other collaterals and in case the PIP
            //       changes to an OSM.
            DssExecLib.authorize(_clip, DssExecLib.clipperMom());
            DssExecLib.setValue(_clip, "stopped", 0);
            // Use Abacus/LinearDecrease
            DssExecLib.setContract(_clip, "calc", MCD_CLIP_CALC_PAXUSD_A);
            // Set Liquidation Penalty to 0
            DssExecLib.setIlkLiquidationPenalty(_ilk, 0);
            // Set Auction Price Multiplier (buf) to 1
            DssExecLib.setStartingPriceMultiplicativeFactor(_ilk, 100_00);
            // Set Local Liquidation Limit (ilk.hole) to 3m DAI
            DssExecLib.setIlkMaxLiquidationAmount(_ilk, 3_000_000);
            // Set tau for Abacus/LinearDecrease to 4,320,000 second
            DssExecLib.setLinearDecrease(MCD_CLIP_CALC_PAXUSD_A, 4_320_000);
            // Set Max Auction Duration (tail) to 43,200 seconds
            DssExecLib.setAuctionTimeBeforeReset(_ilk, 43_200);
            // Set Max Auction Drawdown / Permitted Drop (cusp) to 0.99
            DssExecLib.setAuctionPermittedDrop(_ilk, 99_00);
            // Set Proportional Kick Incentive (chip) to 0
            DssExecLib.setKeeperIncentivePercent(_ilk, 0);
            // Set Flat Kick Incentive (tip) to 0
            DssExecLib.setKeeperIncentiveFlatRate(_ilk, 0);
        }

        // ----------------- Whitelist Light Feed on Oracle for rETH -----------------
        // https://forum.makerdao.com/t/whitelist-light-feed-for-reth-oracle/18908
        address[] memory lightFeeds = new address[](1);
        lightFeeds[0] = RETH_LIGHTFEED;
        OracleLiftLike(RETH_ORACLE).lift(lightFeeds);

        // ------------------ Setup new Starknet Governance Relay -----------------

        // Relay l2 part of the spell
        // https://voyager.online/contract/0x013c117c7bdb9dbbb45813fd6de8e301bbceed2cfad7c4c589cafa4478104672#code
        StarknetGovRelayLike(STARKNET_GOV_RELAY).relay(L2_GOV_RELAY_SPELL);

        // ----------------- MKR Transfer -----------------
        TokenLike(DssExecLib.mkr()).transfer(DUX_WALLET, 180.6 ether);

        // Configure Chainlog
        DssExecLib.setChangelogAddress("STARKNET_GOV_RELAY_LEGACY", STARKNET_GOV_RELAY);
        DssExecLib.setChangelogAddress("STARKNET_GOV_RELAY", NEW_STARKNET_GOV_RELAY);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_GUSD_A", MCD_CLIP_CALC_GUSD_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_USDC_A", MCD_CLIP_CALC_USDC_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_PAXUSD_A", MCD_CLIP_CALC_PAXUSD_A);

        DssExecLib.setChangelogVersion("1.14.6");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
