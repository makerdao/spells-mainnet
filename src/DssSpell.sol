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

import { VatAbstract } from "dss-interfaces/dss/VatAbstract.sol";
import { GemAbstract } from "dss-interfaces/ERC/GemAbstract.sol";

interface RwaLiquidationLike {
    function bump(bytes32 ilk, uint256 val) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-08-18 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // ---------- DAO Resolution for BlockTower Andromeda ----------
    // Forum: https://forum.makerdao.com/t/dao-resolution-to-facilitate-onboarding-of-taco-with-additional-third-parties/21572
    // Forum: https://forum.makerdao.com/t/dao-resolution-to-facilitate-onboarding-of-taco-with-additional-third-parties/21572/2

    // Include IPFS hash QmUNrCwKK2iK2ki5Spn97jrTCDKqFjDZWKk3wxQ2psgMP5 (not a `doc` update)
    // NOTE: by the previous convention it should be a comma-separated list of DAO resolutions IPFS hashes
    string public constant dao_resolutions = "QmUNrCwKK2iK2ki5Spn97jrTCDKqFjDZWKk3wxQ2psgMP5";

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
    uint256 internal constant THREE_PT_THREE_THREE_PCT_RATE = 1000000001038735548426731741;
    uint256 internal constant THREE_PT_FIVE_EIGHT_PCT_RATE  = 1000000001115362602336059074;
    uint256 internal constant FOUR_PT_ZERO_EIGHT_PCT_RATE   = 1000000001268063427242299977;
    uint256 internal constant FIVE_PCT_RATE                 = 1000000001547125957863212448;
    uint256 internal constant FIVE_PT_TWO_FIVE_PCT_RATE     = 1000000001622535724756171269;
    uint256 internal constant FIVE_PT_FIVE_FIVE_PCT_RATE    = 1000000001712791360746325100;
    uint256 internal constant FIVE_PT_EIGHT_PCT_RATE        = 1000000001787808646832390371;
    uint256 internal constant SIX_PT_THREE_PCT_RATE         = 1000000001937312893803622469;
    uint256 internal constant SEVEN_PCT_RATE                = 1000000002145441671308778766;

    // ---------- Math ----------
    uint256 internal constant THOUSAND = 10 ** 3;
    uint256 internal constant MILLION  = 10 ** 6;
    uint256 internal constant BILLION  = 10 ** 9;
    uint256 internal constant RAY      = 10 ** 27;
    uint256 internal constant RAD      = 10 ** 45;

    // ---------- Smart Burn Engine Parameter Updates ----------
    address internal immutable MCD_VOW            = DssExecLib.vow();
    address internal immutable MCD_FLAP           = DssExecLib.flap();

    // ---------- CRVV1ETHSTETH-A 2nd Stage Offboarding ----------
    VatAbstract internal immutable vat  = VatAbstract(DssExecLib.vat());
    address internal immutable MCD_SPOT = DssExecLib.spotter();

    // ---------- Aligned Delegate Compensation for July 2023 ----------
    GemAbstract internal immutable mkr                    = GemAbstract(DssExecLib.mkr());
    address internal constant DEFENSOR                    = 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9;
    address internal constant BONAPUBLICA                 = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant QGOV                        = 0xB0524D8707F76c681901b782372EbeD2d4bA28a6;
    address internal constant TRUENAME                    = 0x612F7924c367575a0Edf21333D96b15F1B345A5d;
    address internal constant UPMAKER                     = 0xbB819DF169670DC71A16F58F55956FE642cc6BcD;
    address internal constant VIGILANT                    = 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61;
    address internal constant WBC                         = 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47;
    address internal constant PALC                        = 0x78Deac4F87BD8007b9cb56B8d53889ed5374e83A;
    address internal constant NAVIGATOR                   = 0x11406a9CC2e37425F15f920F494A51133ac93072;
    address internal constant PBG                         = 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2;
    address internal constant VOTEWIZARD                  = 0x9E72629dF4fcaA2c2F5813FbbDc55064345431b1;
    address internal constant LIBERTAS                    = 0xE1eBfFa01883EF2b4A9f59b587fFf1a5B44dbb2f;
    address internal constant HARMONY                     = 0xF4704Aa4Ad22cAA2A3Dd7A7C529B4C32f7A421F2;
    address internal constant JAG                         = 0x58D1ec57E4294E4fe650D1CB12b96AE34349556f;
    address internal constant CLOAKY                      = 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818;
    address internal constant SKYNET                      = 0xd4d1A446cD5976a11bd32D3e815A9F85FED2F9F3;

    // ---------- New Silver Parameter Changes ----------
    address internal immutable MIP21_LIQUIDATION_ORACLE = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");

    function actions() public override {
        // ---------- EDSR Update ----------
        // Forum: https://forum.makerdao.com/t/request-for-gov12-1-2-edit-to-the-stability-scope-to-quickly-modify-enhanced-dsr-based-on-observed-data/21581

        // Reduce DSR by 3% from 8% to 5%
        DssExecLib.setDSR(FIVE_PCT_RATE, /* doDrip = */ true);

        // ---------- DSR-based Stability Fee Updates ----------
        // Forum: https://forum.makerdao.com/t/request-for-gov12-1-2-edit-to-the-stability-scope-to-quickly-modify-enhanced-dsr-based-on-observed-data/21581

        // Increase ETH-A SF by 0.14% from 3.44% to 3.58%
        DssExecLib.setIlkStabilityFee("ETH-A", THREE_PT_FIVE_EIGHT_PCT_RATE, /* doDrip = */ true);

        // Increase ETH-B SF by 0.14% from 3.94%% to 4.08%
        DssExecLib.setIlkStabilityFee("ETH-B", FOUR_PT_ZERO_EIGHT_PCT_RATE, /* doDrip = */ true);

        // Increase ETH-C SF by 0.14% from 3.19% to 3.33%
        DssExecLib.setIlkStabilityFee("ETH-C", THREE_PT_THREE_THREE_PCT_RATE, /* doDrip = */ true);

        // Increase WSTETH-A SF by 1.81% from 3.44% to 5.25%
        DssExecLib.setIlkStabilityFee("WSTETH-A", FIVE_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WSTETH-B SF by 1.81% from 3.19% to 5.00%
        DssExecLib.setIlkStabilityFee("WSTETH-B", FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase RETH-A SF by 1.81% from 3.44% to 5.25%
        DssExecLib.setIlkStabilityFee("RETH-A", FIVE_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-A SF by 0.11% from 5.69% to 5.80%
        DssExecLib.setIlkStabilityFee("WBTC-A", FIVE_PT_EIGHT_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-B SF by 0.11% from 6.19% to 6.30%
        DssExecLib.setIlkStabilityFee("WBTC-B", SIX_PT_THREE_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-C SF by 0.11% from 5.44% to 5.55%
        DssExecLib.setIlkStabilityFee("WBTC-C", FIVE_PT_FIVE_FIVE_PCT_RATE, /* doDrip = */ true);

        // ---------- Smart Burn Engine Parameter Updates ----------
        // Poll: https://vote.makerdao.com/polling/QmTRJNNH
        // Forum: https://forum.makerdao.com/t/smart-burn-engine-parameters-update-1/21545

        // Increase vow.bump by 15,000 DAI from 5,000 DAI to 20,000 DAI
        DssExecLib.setValue(MCD_VOW, "bump", 20 * THOUSAND * RAD);

        // Increase hop by 4,731 seconds from 1,577 seconds to 6,308 seconds
        DssExecLib.setValue(MCD_FLAP, "hop", 6_308);

        // ---------- Non-DSR Related Parameter Changes ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-4/21567
        // Mip: https://mips.makerdao.com/mips/details/MIP104#14-3-native-vault-engine

        // Increase WSTETH-A line by 250 million DAI from 500 million DAI to 750 million DAI (no change to gap or ttl)
        DssExecLib.setIlkAutoLineDebtCeiling("WSTETH-A", 750 * MILLION);

        // Increase WSTETH-B line by 500 million DAi from 500 million DAI to 1 billion DAI
        // Increase WSTETH-B gap by 15 million DAI from 30 million DAI to 45 million DAI
        // Reduce WSTETH-B ttl by 14,400 seconds from 57,600 seconds to 43,200 seconds
        // Forum: https://forum.makerdao.com/t/non-scope-defined-parameter-changes-wsteth-b-dc-iam/21568
        // Poll: https://vote.makerdao.com/polling/QmPxbrBZ#poll-detail
        DssExecLib.setIlkAutoLineParameters("WSTETH-B", 1 * BILLION, 45 * MILLION, 12 hours);

        // Increase RETH-A line by 25 million DAI from 50 million DAI to 75 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("RETH-A", 75 * MILLION);

        // ---------- CRVV1ETHSTETH-A 2nd Stage Offboarding ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-4/21567#crvv1ethsteth-a-offboarding-parameters-13
        // Mip: https://mips.makerdao.com/mips/details/MIP104#14-3-native-vault-engine

        // Set chop to 0%
        DssExecLib.setIlkLiquidationPenalty("CRVV1ETHSTETH-A", 0);

        // Set tip to 0%
        DssExecLib.setKeeperIncentiveFlatRate("CRVV1ETHSTETH-A", 0);

        // Set chip to 0%
        DssExecLib.setKeeperIncentivePercent("CRVV1ETHSTETH-A", 0);

        // Set Liquidation Ratio to 10,000%
        // NOTE: We are using low level methods because DssExecLib only allows setting `mat < 1000%`: https://github.com/makerdao/dss-exec-lib/blob/69b658f35d8618272cd139dfc18c5713caf6b96b/src/DssExecLib.sol#L717
        DssExecLib.setValue(MCD_SPOT, "CRVV1ETHSTETH-A", "mat", 100 * RAY);

        // NOTE: Update collateral price to propagate the changes
        DssExecLib.updateCollateralPrice("CRVV1ETHSTETH-A");

        // Reduce Global Debt Ceiling by 100 million DAI to account for offboarded collateral
        DssExecLib.decreaseGlobalDebtCeiling(100 * MILLION);

        // ---------- Aligned Delegate Compensation for July 2023 ----------
        // Forum: https://forum.makerdao.com/t/july-2023-aligned-delegate-compensation/21632

        // 0xDefensor - 29.76 MKR - 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9
        mkr.transfer(DEFENSOR,       29.76 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // BONAPUBLICA - 29.76 MKR - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        mkr.transfer(BONAPUBLICA,    29.76 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // QGov - 29.76 MKR - 0xB0524D8707F76c681901b782372EbeD2d4bA28a6
        mkr.transfer(QGOV,           29.76 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // TRUE NAME - 29.76 MKR - 0x612f7924c367575a0edf21333d96b15f1b345a5d
        mkr.transfer(TRUENAME,       29.76 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // UPMaker - 29.76 MKR - 0xbb819df169670dc71a16f58f55956fe642cc6bcd
        mkr.transfer(UPMAKER,        29.76 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // vigilant - 29.76 MKR - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        mkr.transfer(VIGILANT,       29.76 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // WBC - 14.82 MKR - 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47
        mkr.transfer(WBC,            14.82 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // PALC - 13.89 MKR - 0x78Deac4F87BD8007b9cb56B8d53889ed5374e83A
        mkr.transfer(PALC,           13.89 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // Navigator - 11.24 MKR - 0x11406a9CC2e37425F15f920F494A51133ac93072
        mkr.transfer(NAVIGATOR,      11.24 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // PBG - 9.92 MKR - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        mkr.transfer(PBG,            9.92 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // VoteWizard - 9.92 MKR - 0x9E72629dF4fcaA2c2F5813FbbDc55064345431b1
        mkr.transfer(VOTEWIZARD,     9.92 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // Libertas - 9.92 MKR - 0xE1eBfFa01883EF2b4A9f59b587fFf1a5B44dbb2f
        mkr.transfer(LIBERTAS,       9.92 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // Harmony - 8.93 MKR - 0xF4704Aa4Ad22cAA2A3Dd7A7C529B4C32f7A421F2
        mkr.transfer(HARMONY,        8.93 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // JAG - 7.61 MKR - 0x58D1ec57E4294E4fe650D1CB12b96AE34349556f
        mkr.transfer(JAG,            7.61 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // Cloaky - 4.30 MKR - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        mkr.transfer(CLOAKY,         4.30 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // Skynet - 3.64 MKR - 0xd4d1A446cD5976a11bd32D3e815A9F85FED2F9F3
        mkr.transfer(SKYNET,         3.64 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // ---------- Old D3M Parameter Housekeeping ----------
        // Forum: https://forum.makerdao.com/t/notice-of-executive-vote-date-change-and-housekeeping-changes/21613

        // NOTE: Variables to calculate decrease of the global debt ceiling
        uint256 line;
        uint256 globalLineReduction = 0;

        // Remove DIRECT-AAVEV2-DAI from autoline
        DssExecLib.removeIlkFromAutoLine("DIRECT-AAVEV2-DAI");

        // Set DIRECT-AAVEV2-DAI Debt Ceiling to 0
        (,,,line,) = vat.ilks("DIRECT-AAVEV2-DAI");
        globalLineReduction += line;
        DssExecLib.setIlkDebtCeiling("DIRECT-AAVEV2-DAI", 0);

        // Remove DIRECT-COMPV2-DAI from autoline
        DssExecLib.removeIlkFromAutoLine("DIRECT-COMPV2-DAI");

        // Set DIRECT-COMPV2-DAI Debt Ceiling to 0
        (,,,line,) = vat.ilks("DIRECT-COMPV2-DAI");
        globalLineReduction += line;
        DssExecLib.setIlkDebtCeiling("DIRECT-COMPV2-DAI", 0);

        // Reduce Global Debt Ceiling? Yes
        vat.file("Line", vat.Line() - globalLineReduction);

        // ---------- New Silver Parameter Changes ----------
        // Forum: https://forum.makerdao.com/t/rwa-002-new-silver-restructuring-risk-and-legal-assessment/21417
        // Poll: https://vote.makerdao.com/polling/QmaU1eaD#poll-detail

        // Increase RWA002-A Debt Ceiling by 30 million DAI from 20 million DAI to 50 million DAI
        DssExecLib.increaseIlkDebtCeiling(
            "RWA002-A",
            30 * MILLION,
            true // Increase global Line
        );

        // Increase RWA002-A Stability Fee by 3.5% from 3.5% to 7%
        DssExecLib.setIlkStabilityFee("RWA002-A", SEVEN_PCT_RATE, /* doDrip = */ true);

        // Reduce Liquidation Ratio by 5% from 105% to 100%
        // Forum: https://forum.makerdao.com/t/notice-of-executive-vote-date-change-and-housekeeping-changes/21613
        DssExecLib.setIlkLiquidationRatio("RWA002-A", 100_00);

        // Bump Oracle price to account for new DC and SF
        // NOTE: the formula is `Debt ceiling * [ (1 + RWA stability fee ) ^ (minimum deal duration in years) ] * liquidation ratio`
        // Since RWA002-A Termination Date is `October 11, 2032`, and spell execution time is `2023-08-18`, the distance is `3342` days
        // bc -l <<< 'scale=18; 50000000 * e(l(1.07) * (3342/365)) * 1.00' | cast --to-wei
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).bump(
            "RWA002-A",
            92_899_355_926924134500000000
        );

        // NOTE: Update collateral price to propagate the changes
        DssExecLib.updateCollateralPrice("RWA002-A");

        // ---------- Transfer Spark Proxy Admin Controls ----------

        // ---------- Trigger Spark Proxy Spell ----------
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
