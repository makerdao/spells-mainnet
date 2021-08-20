// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
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
pragma experimental ABIEncoderV2;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

interface RwaOutputConduitLike {
    function kiss(address) external;
    function diss(address) external;
}

interface Bumpable {
    function bump(bytes32, uint256) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/40b362fc70793e9980a8d53c47b1937e05d0c6d3/governance/votes/Executive%20vote%20-%20August%2020%2C%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-08-20 MakerDAO Executive Spell | Hash: 0x2b31d3c81f06eac1e304c3c8b257878729f518d1f9632d95c37efa19241eb8a7";

    // Foundation SC team old deployer address (for removal from RWA output conduit)
    address constant SC_DOMAIN_DEPLOYER_07 = 0xDA0FaB0700A4389F6E6679aBAb1692B4601ce9bf;

    // Genesis broker/dealer address for 6s (for addition to RWA output conduit):
    // https://forum.makerdao.com/t/6s-broker-dealer-dai-address/9780
    address constant GENESIS_6S = 0xE5C35757c296FD19faA2bFF85e66C6B25AC8b978;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant ZERO_PCT_RATE  = 1000000000000000000000000000;
    uint256 constant THREE_PCT_RATE = 1000000000937303470807876289;

    // Math
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    address constant MATIC                 = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0;
    address constant MCD_JOIN_MATIC_A      = 0x885f16e177d45fC9e7C87e1DA9fd47A9cfcE8E13;
    address constant MCD_CLIP_MATIC_A      = 0x29342F530ed6120BDB219D602DaFD584676293d1;
    address constant MCD_CLIP_CALC_MATIC_A = 0xdF8C347B06a31c6ED11f8213C2366348BFea68dB;
    address constant PIP_MATIC             = 0x8874964279302e6d4e523Fb1789981C39a1034Ba;

    address constant PAX                     = 0x8E870D67F660D95d5be530380D0eC0bd388289E1;
    address constant MCD_JOIN_PSM_PAX_A      = 0x7bbd8cA5e413bCa521C2c80D8d1908616894Cf21;
    address constant MCD_CLIP_PSM_PAX_A      = 0x5322a3551bc6a1b39d5D142e5e38Dc5B4bc5B3d2;
    address constant MCD_CLIP_CALC_PSM_PAX_A = 0xC19eAc21A4FccdD30812F5fF5FebFbD6817b7593;
    address constant MCD_PSM_PAX_A           = 0x961Ae24a1Ceba861D1FDf723794f6024Dc5485Cf;
    address constant PIP_PSM_PAX             = 0x043B963E1B2214eC90046167Ea29C2c8bDD7c0eC;

    address constant CALC_FAB              = 0xE1820A2780193d74939CcA104087CADd6c1aA13A;

    function actions() public override {

        //
        // RWA Updates
        //
        bytes32 ilk = bytes32("RWA001-A");
        address MIP21_LIQUIDATION_ORACLE = DssExecLib.getChangelogAddress(
            "MIP21_LIQUIDATION_ORACLE"
        );
        address RWA001_A_OUTPUT_CONDUIT = DssExecLib.getChangelogAddress(
            "RWA001_A_OUTPUT_CONDUIT"
        );

        // This old foundation deployer address address was only used to test
        // the circuit, and must be removed before the debt ceiling goes live.
        RwaOutputConduitLike(RWA001_A_OUTPUT_CONDUIT).diss(
            SC_DOMAIN_DEPLOYER_07
        );

        // Adds the Genesis broker/dealer address to the output conduit
        RwaOutputConduitLike(RWA001_A_OUTPUT_CONDUIT).kiss(GENESIS_6S);

        // increase the ilk and global DC. Check page 9 of the term sheet here:
        // https://forum.makerdao.com/t/mip13c3-sp4-declaration-of-intent-commercial-points-off-chain-asset-backed-lender-to-onboard-real-world-assets-as-collateral-for-a-dai-loan/3914
        // executive ratification here:
        // https://vote.makerdao.com/executive/template-executive-vote-approve-october-2020-governance-cycle-bundle-october-26-2020?network=mainnet#proposal-detail
        DssExecLib.increaseIlkDebtCeiling(
            ilk,
            14_999_000,  // DC to 15 million less the existing 1000
            true
        );

        // Increase the price to enable DAI to be drawn -- value corresponds to
        // [ (debt ceiling) + (2 years interest at current rate) ] * mat, i.e.
        // 15MM * 1.03^2 * 1.00 as a WAD
        Bumpable(MIP21_LIQUIDATION_ORACLE).bump(ilk, 15_913_500 * WAD);
        DssExecLib.updateCollateralPrice(ilk);


        // PAX PSM
        // https://vote.makerdao.com/polling/QmdBrVKD#poll-detail
        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_PSM_PAX_A, 120 seconds, 9990);

        CollateralOpts memory PSM_PAX_A = CollateralOpts({
            ilk:                   "PSM-PAX-A",
            gem:                   PAX,
            join:                  MCD_JOIN_PSM_PAX_A,
            clip:                  MCD_CLIP_PSM_PAX_A,
            calc:                  MCD_CLIP_CALC_PSM_PAX_A,
            pip:                   PIP_PSM_PAX,
            isLiquidatable:        false,
            isOSM:                 false,
            whitelistOSM:          false,
            ilkDebtCeiling:        50 * MILLION,
            minVaultAmount:        0,
            maxLiquidationAmount:  0,
            liquidationPenalty:    1300,
            ilkStabilityFee:       ZERO_PCT_RATE,
            startingPriceFactor:   10500,
            breakerTolerance:      9500, // Allows for a 5% hourly price drop before disabling liquidations
            auctionDuration:       220 minutes,
            permittedDrop:         9000,
            liquidationRatio:      10000,
            kprFlatReward:         300,
            kprPctReward:          10 // 0.1%
        });

        DssExecLib.addNewCollateral(PSM_PAX_A);

        DssExecLib.setValue(MCD_PSM_PAX_A, "tin", 1 * WAD / 1000);
        DssExecLib.setValue(MCD_PSM_PAX_A, "tout", 0);

        DssExecLib.setChangelogAddress("MCD_JOIN_PSM_PAX_A", MCD_JOIN_PSM_PAX_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_PSM_PAX_A", MCD_CLIP_PSM_PAX_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_PSM_PAX_A", MCD_CLIP_CALC_PSM_PAX_A);
        DssExecLib.setChangelogAddress("MCD_PSM_PAX_A", MCD_PSM_PAX_A);
        DssExecLib.setChangelogAddress("PIP_PSM_PAX", PIP_PSM_PAX);

        // Set USDC tin value to 0.2%
        DssExecLib.setValue(DssExecLib.getChangelogAddress("MCD_PSM_USDC_A"), "tin", 2 * WAD / 1000);

        //
        // MATIC Onboarding
        // https://vote.makerdao.com/polling/QmeRhDHX?network=mainnet#poll-detail
        // https://forum.makerdao.com/t/matic-collateral-onboarding-risk-evaluation/9069

        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_MATIC_A, 90 seconds, 9900);

        CollateralOpts memory MATIC_A = CollateralOpts({
            ilk:                   "MATIC-A",
            gem:                   MATIC,
            join:                  MCD_JOIN_MATIC_A,
            clip:                  MCD_CLIP_MATIC_A,
            calc:                  MCD_CLIP_CALC_MATIC_A,
            pip:                   PIP_MATIC,
            isLiquidatable:        true,
            isOSM:                 true,
            whitelistOSM:          true,
            ilkDebtCeiling:        3 * MILLION,
            minVaultAmount:        10 * THOUSAND,
            maxLiquidationAmount:  3 * MILLION,
            liquidationPenalty:    1300,
            ilkStabilityFee:       THREE_PCT_RATE,
            startingPriceFactor:   13000,
            breakerTolerance:      5000, // Allows for a 50% hourly price drop before disabling liquidations
            auctionDuration:       140 minutes,
            permittedDrop:         4000,
            liquidationRatio:      17500,
            kprFlatReward:         300,
            kprPctReward:          10 // 0.1%
        });

        DssExecLib.addNewCollateral(MATIC_A);
        DssExecLib.setIlkAutoLineParameters("MATIC-A", 10 * MILLION, 3 * MILLION, 8 hours);

        DssExecLib.setChangelogAddress("MATIC", MATIC);
        DssExecLib.setChangelogAddress("MCD_JOIN_MATIC_A", MCD_JOIN_MATIC_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_MATIC_A", MCD_CLIP_MATIC_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_MATIC_A", MCD_CLIP_CALC_MATIC_A);
        DssExecLib.setChangelogAddress("PIP_MATIC", PIP_MATIC);


        // Liquidation Ratio
        // https://vote.makerdao.com/polling/QmZQdJpG?network=mainnet#poll-detail
        DssExecLib.setIlkLiquidationRatio("ETH-A", 14500);
        DssExecLib.setIlkLiquidationRatio("WBTC-A", 14500);
        DssExecLib.setIlkLiquidationRatio("ETH-C", 17000);
        DssExecLib.setIlkLiquidationRatio("LINK-A", 16500);
        DssExecLib.setIlkLiquidationRatio("UNIV2DAIETH-A", 12000);
        DssExecLib.setIlkLiquidationRatio("YFI-A", 16500);
        DssExecLib.setIlkLiquidationRatio("UNIV2WBTCETH-A", 14500);
        DssExecLib.setIlkLiquidationRatio("UNIV2UNIETH-A", 16000);
        DssExecLib.setIlkLiquidationRatio("UNIV2USDCETH-A", 12000);
        DssExecLib.setIlkLiquidationRatio("RENBTC-A", 16500);
        DssExecLib.setIlkLiquidationRatio("UNI-A", 16500);
        DssExecLib.setIlkLiquidationRatio("AAVE-A", 16500);
        DssExecLib.setIlkLiquidationRatio("UNIV2WBTCDAI-A", 12000);
        DssExecLib.setIlkLiquidationRatio("BAL-A", 16500);
        DssExecLib.setIlkLiquidationRatio("COMP-A", 16500);


        // Housekeeping
        DssExecLib.setChangelogAddress("CALC_FAB", CALC_FAB);


        // Bump changelog version
        DssExecLib.setChangelogVersion("1.9.4");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
