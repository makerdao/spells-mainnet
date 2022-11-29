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

import { VatAbstract } from "dss-interfaces/dss/VatAbstract.sol";
import { JugAbstract } from "dss-interfaces/dss/JugAbstract.sol";
import { SpotAbstract } from "dss-interfaces/dss/SpotAbstract.sol";
import { IlkRegistryAbstract } from "dss-interfaces/dss/IlkRegistryAbstract.sol";

interface D3MHubLike {
    function vat() external view returns (address);
    function daiJoin() external view returns (address);
    function file(bytes32, address) external;
    function file(bytes32, bytes32, address) external;
    function file(bytes32, bytes32, uint256) external;
}

interface D3MMomLike {
    function setAuthority(address) external;
}

interface D3MCompoundPoolLike {
    function ilk() external view returns (bytes32);
    function vat() external view returns (address);
    function dai() external view returns (address);
    function file(bytes32, address) external;
    function rely(address) external;
}

interface D3MCompoundPlanLike {
    function rely(address) external;
    function file(bytes32, uint256) external;
}

interface D3MOracleLike {
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function file(bytes32, address) external;
}

interface StarknetGovRelayLike {
    function relay(uint256 spell) external;
}

interface OSMLike {
    function src() external view returns (address);
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

    uint256 constant internal RAY = 10 ** 27;
    uint256 constant internal RAD = 10 ** 45;
    uint256 constant internal MILLION = 10 ** 6;

    bytes32 constant internal ILK = "DIRECT-COMPV2-DAI";

    address constant internal D3M_HUB = 0x12F36cdEA3A28C35aC8C6Cc71D9265c17C74A27F;
    address constant internal D3M_MOM = 0x1AB3145E281c01a1597c8c62F9f060E8e3E02fAB;
    address immutable internal D3M_MOM_LEGACY = DssExecLib.getChangelogAddress("DIRECT_MOM");
    address constant internal D3M_COMPOUND_POOL = 0x621fE4Fde2617ea8FFadE08D0FF5A862aD287EC2;
    address constant internal D3M_COMPOUND_PLAN = 0xD0eA20f9f9e64A3582d569c8745DaCD746274AEe;
    address constant internal D3M_ORACLE = 0x0e2bf18273c953B54FE0a9dEC5429E67851D9468;

    // target 2% borrow apy, see top of D3MCompoundPlan for the formula explanation
    // ((2.00 / 100) + 1) ^ (1 / 365) - 1) / 7200) * 10^18
    uint256 constant internal D3M_COMP_BORROW_RATE = 7535450719;

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
        {
            VatAbstract vat = VatAbstract(DssExecLib.vat());
            SpotAbstract spot = SpotAbstract(DssExecLib.spotter());
            address daiJoin = DssExecLib.daiJoin();
            address dai = DssExecLib.dai();
            address vow = DssExecLib.vow();
            address end = DssExecLib.end();

            // Sanity checks
            require(D3MHubLike(D3M_HUB).vat() == address(vat), "Hub vat mismatch");
            require(D3MHubLike(D3M_HUB).daiJoin() == daiJoin, "Hub daiJoin mismatch");

            require(D3MCompoundPoolLike(D3M_COMPOUND_POOL).ilk() == ILK, "Pool ilk mismatch");
            require(D3MCompoundPoolLike(D3M_COMPOUND_POOL).vat() == address(vat), "Pool vat mismatch");
            require(D3MCompoundPoolLike(D3M_COMPOUND_POOL).dai() == dai, "Pool dai mismatch");

            require(D3MOracleLike(D3M_ORACLE).vat() == address(vat), "Oracle vat mismatch");
            require(D3MOracleLike(D3M_ORACLE).ilk() == ILK, "Oracle ilk mismatch");

            D3MHubLike(D3M_HUB).file(ILK, "pool", D3M_COMPOUND_POOL);
            D3MHubLike(D3M_HUB).file(ILK, "plan", D3M_COMPOUND_PLAN);
            D3MHubLike(D3M_HUB).file(ILK, "tau", 7 days);
            D3MHubLike(D3M_HUB).file("vow", vow);
            D3MHubLike(D3M_HUB).file("end", end);

            D3MMomLike(D3M_MOM).setAuthority(DssExecLib.getChangelogAddress("MCD_ADM"));

            D3MCompoundPoolLike(D3M_COMPOUND_POOL).file("king", address(this));

            D3MCompoundPlanLike(D3M_COMPOUND_PLAN).rely(D3M_MOM);
            D3MCompoundPlanLike(D3M_COMPOUND_PLAN).file("barb", D3M_COMP_BORROW_RATE);

            D3MOracleLike(D3M_ORACLE).file("hub", D3M_HUB);

            spot.file(ILK, "pip", D3M_ORACLE);
            spot.file(ILK, "mat", RAY);
            vat.rely(D3M_HUB);
            vat.init(ILK);
            JugAbstract(DssExecLib.jug()).init(ILK);
            DssExecLib.increaseGlobalDebtCeiling(5 * MILLION);
            DssExecLib.setIlkDebtCeiling(ILK, 5 * MILLION);
            DssExecLib.setIlkAutoLineParameters(ILK, 5 * MILLION, 5 * MILLION, 12 hours);
            DssExecLib.updateCollateralPrice(ILK);

            // Add to ilk registry
            IlkRegistryAbstract(DssExecLib.reg()).put(
                ILK,
                D3M_HUB,
                address(0),
                0,
                4,
                address(0),
                address(0),
                "",
                ""
            );
        }

        // ----------------- Activate Liquidations for GUSD-A, USDC-A and USDP-A -----------------
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
        require(OSMLike(DssExecLib.getChangelogAddress("PIP_RETH")).src() == RETH_ORACLE, "Bad oracle address");
        address[] memory lightFeeds = new address[](1);
        lightFeeds[0] = RETH_LIGHTFEED;
        OracleLiftLike(RETH_ORACLE).lift(lightFeeds);

        // ------------------ Setup new Starknet Governance Relay -----------------
        // Forum: https://forum.makerdao.com/t/starknet-changes-for-executive-spell-on-the-week-of-2022-11-29/18818
        // Relay l2 part of the spell
        // L2 Spell: https://voyager.online/contract/0x013c117c7bdb9dbbb45813fd6de8e301bbceed2cfad7c4c589cafa4478104672#code
        StarknetGovRelayLike(STARKNET_GOV_RELAY).relay(L2_GOV_RELAY_SPELL);

        // ----------------- MKR Transfer -----------------
        TokenLike(DssExecLib.mkr()).transfer(DUX_WALLET, 180.6 ether);

        // Configure Chainlog
        DssExecLib.setChangelogAddress("DIRECT_HUB", D3M_HUB);
        DssExecLib.setChangelogAddress("DIRECT_MOM", D3M_MOM);
        DssExecLib.setChangelogAddress("DIRECT_MOM_LEGACY", D3M_MOM_LEGACY);

        DssExecLib.setChangelogAddress("DIRECT_COMPV2_DAI_POOL", D3M_COMPOUND_POOL);
        DssExecLib.setChangelogAddress("DIRECT_COMPV2_DAI_PLAN", D3M_COMPOUND_PLAN);
        DssExecLib.setChangelogAddress("DIRECT_COMPV2_DAI_ORACLE", D3M_ORACLE);

        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_GUSD_A", MCD_CLIP_CALC_GUSD_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_USDC_A", MCD_CLIP_CALC_USDC_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_PAXUSD_A", MCD_CLIP_CALC_PAXUSD_A);

        DssExecLib.setChangelogAddress("STARKNET_GOV_RELAY_LEGACY", STARKNET_GOV_RELAY);
        DssExecLib.setChangelogAddress("STARKNET_GOV_RELAY", NEW_STARKNET_GOV_RELAY);

        DssExecLib.setChangelogVersion("1.14.6");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
