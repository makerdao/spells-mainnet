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
import { VatAbstract } from "dss-interfaces/dss/VatAbstract.sol";

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-01-24 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
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
    // uint256 internal constant X_PCT_RATE = ;
    uint256 internal constant SIX_PT_FOUR_FIVE_PCT_RATE  = 1000000001982027061559507021;
    uint256 internal constant SIX_PT_FOUR_NINE_PCT_RATE  = 1000000001993940198563273844;
    uint256 internal constant SIX_PT_SEVEN_PCT_RATE      = 1000000002056410844314321266;
    uint256 internal constant SIX_PT_SEVEN_FOUR_PCT_RATE = 1000000002068296073857195778;
    uint256 internal constant SIX_PT_NINE_ONE_PCT_RATE   = 1000000002118758660201099744;
    uint256 internal constant SEVEN_PT_ONE_SIX_PCT_RATE  = 1000000002192822766493423465;
    uint256 internal constant SEVEN_PT_TWO_PCT_RATE      = 1000000002204656986467871801;
    uint256 internal constant SEVEN_PT_TWO_FOUR_PCT_RATE = 1000000002216486791512316847;

    // ---------- Math ----------
    uint256 internal constant THOUSAND = 10 ** 3;
    uint256 internal constant RAY      = 10 ** 27;
    uint256 internal constant RAD      = 10 ** 45;

    // ---------- Reduce PSM-PAX-A Debt Ceiling & Disable DC-IAM ----------
    VatAbstract internal immutable vat = VatAbstract(DssExecLib.vat());

    // ---------- RETH-A Offboarding Parameters Finalization ----------
    address internal immutable MCD_SPOT = DssExecLib.spotter();

    // ---------- SBE parameter changes ----------
    address internal immutable MCD_VOW  = DssExecLib.vow();
    address internal immutable MCD_FLAP = DssExecLib.flap();

    // ---------- Approve HV Bank (RWA009-A) DAO Resolution ----------
    // Forum: https://forum.makerdao.com/t/huntingdon-valley-bank-transaction-documents-on-permaweb/16264/21

    // Approve DAO resolution hash QmVtqkYtx61wEeM5Hb92dGA3TMZ9F1Z5WDSNwcszqxiF1w
    // Note: by the previous convention it should be a comma-separated list of DAO resolutions IPFS hashes
    string public constant dao_resolutions = "QmVtqkYtx61wEeM5Hb92dGA3TMZ9F1Z5WDSNwcszqxiF1w";

    address internal constant RWA009_A_INPUT_CONDUIT_URN_USDC = 0x08012Ec53A7fAbf6F33318dfb93C1289886eBBE1;
    address internal immutable MCD_ESM                        = DssExecLib.esm();

    // ---------- AVC members compensation Q4 2023 ----------
    GemAbstract internal immutable MKR          = GemAbstract(DssExecLib.mkr());
    address internal constant IAMMEEOH          = 0x47f7A5d8D27f259582097E1eE59a07a816982AE9;
    address internal constant DAI_VINCI         = 0x9ee47F0f82F1A6F45C4E1D25Ce95C321D8C8356a;
    address internal constant OPENSKY_2         = 0xf44f97f4113759E0a57756bE49C0655d490Cf19F;
    address internal constant ACREDAOS          = 0xBF9226345F601150F64Ea4fEaAE7E40530763cbd;
    address internal constant FHOMONEYETH       = 0xdbD5651F71ce83d1f0eD275aC456241890a53C74;
    address internal constant RES               = 0x8c5c8d76372954922400e4654AF7694e158AB784;
    address internal constant HARMONY_2         = 0xE20A2e231215e9b7Aa308463F1A7490b2ECE55D3;
    address internal constant LIBERTAS          = 0xE1eBfFa01883EF2b4A9f59b587fFf1a5B44dbb2f;
    address internal constant SEEDLATAMETH      = 0x0087a081a9B430fd8f688c6ac5dD24421BfB060D;
    address internal constant ROOT              = 0xC74392777443a11Dc26Ce8A3D934370514F38A91;

    // ---------- Trigger Spark Proxy Spell ----------
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0xa3836fEF1D314d4c081C2707a7664c3375F29b61;

    function actions() public override {
        // ---------- Stability Fee Changes ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-8/23445

        // Increase the ETH-A Stability Fee (SF) by 1.49%, from 5.25% to 6.74%.
        DssExecLib.setIlkStabilityFee("ETH-A", SIX_PT_SEVEN_FOUR_PCT_RATE, true);

        // Increase the ETH-B Stability Fee (SF) by 1.49%, from 5.75% to 7.24%.
        DssExecLib.setIlkStabilityFee("ETH-B", SEVEN_PT_TWO_FOUR_PCT_RATE, true);

        // Increase the ETH-C Stability Fee (SF) by 1.49%, from 5.00% to 6.49%.
        DssExecLib.setIlkStabilityFee("ETH-C", SIX_PT_FOUR_NINE_PCT_RATE, true);

        // Increase the WSTETH-A Stability Fee (SF) by 1.91%, from 5.25% to 7.16%.
        DssExecLib.setIlkStabilityFee("WSTETH-A", SEVEN_PT_ONE_SIX_PCT_RATE, true);

        // Increase the WSTETH-B Stability Fee (SF) by 1.91%, from 5.00% to 6.91%.
        DssExecLib.setIlkStabilityFee("WSTETH-B", SIX_PT_NINE_ONE_PCT_RATE, true);

        // Increase the WBTC-A Stability Fee (SF) by 0.91%, from 5.79% to 6.70%.
        DssExecLib.setIlkStabilityFee("WBTC-A", SIX_PT_SEVEN_PCT_RATE, true);

        // Increase the WBTC-B Stability Fee (SF) by 0.91%, from 6.29% to 7.20%.
        DssExecLib.setIlkStabilityFee("WBTC-B", SEVEN_PT_TWO_PCT_RATE, true);

        // Increase the WBTC-C Stability Fee (SF) by 0.91%, from 5.54% to 6.45%.
        DssExecLib.setIlkStabilityFee("WBTC-C", SIX_PT_FOUR_FIVE_PCT_RATE, true);

        // ---------- Reduce PSM-PAX-A Debt Ceiling & Disable DC-IAM ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-8/23445

        // Note: record currently set debt ceiling for PSM-PAX-A
        (,,,uint256 lineReduction,) = vat.ilks("PSM-PAX-A");

        // Remove PSM-PAX-A from Autoline.
        DssExecLib.removeIlkFromAutoLine("PSM-PAX-A");

        // Set PSM-PAX-A debt ceiling to 0
        DssExecLib.setIlkDebtCeiling("PSM-PAX-A", 0);

        // Reduce Global Debt Ceiling? Yes
        vat.file("Line", vat.Line() - lineReduction);

        // ---------- RETH-A Offboarding Parameters Finalization ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-8/23445

        // Set chop to 0%.
        DssExecLib.setIlkLiquidationPenalty("RETH-A", 0);

        // Set tip to 0%
        DssExecLib.setKeeperIncentiveFlatRate("RETH-A", 0);

        // Set chip to 0%
        DssExecLib.setKeeperIncentivePercent("RETH-A", 0);

        // Set Liquidation Ratio to 10,000%.
        // Note: We are using low level methods because DssExecLib only allows setting `mat < 1000%`: https://github.com/makerdao/dss-exec-lib/blob/69b658f35d8618272cd139dfc18c5713caf6b96b/src/DssExecLib.sol#L717
        DssExecLib.setValue(MCD_SPOT, "RETH-A", "mat", 100 * RAY);

        // Note: Update collateral price to propagate the changes
        DssExecLib.updateCollateralPrice("RETH-A");

        // ---------- SBE parameter changes ----------
        // Forum: https://forum.makerdao.com/t/smart-burn-engine-transaction-analysis-parameter-reconfiguration-update-4/23441

        // Increase bump by 20,000, from 30,000 to 50,000 DAI
        DssExecLib.setValue(MCD_VOW, "bump", 50 * THOUSAND * RAD);

        // Increase hop by 10,512, from 15,768 to 26,280 Seconds
        DssExecLib.setValue(MCD_FLAP, "hop", 26_280);

        // ---------- Approve HV Bank (RWA009-A) DAO Resolution ----------
        // Forum: https://forum.makerdao.com/t/huntingdon-valley-bank-transaction-documents-on-permaweb/16264/21

        // Mainnet - Add RWA009_A_INPUT_CONDUIT_URN_USDC deployed at 0x08012Ec53A7fAbf6F33318dfb93C1289886eBBE1 to the chainlog
        // Forum: https://forum.makerdao.com/t/rwa009-hvbank-mip21-token-ces-domain-team-assessment/15861/15
        DssExecLib.setChangelogAddress("RWA009_A_INPUT_CONDUIT_URN_USDC", RWA009_A_INPUT_CONDUIT_URN_USDC);

        // Call <conduit>.rely(MCD_ESM) to allow ESM module to deny the pause proxy in SwapInputConduit contracts
        DssExecLib.authorize(RWA009_A_INPUT_CONDUIT_URN_USDC, MCD_ESM);

        // Goerli - Add RWA009_A_INPUT_CONDUIT_URN_USDC deployed at 0xddd021b7e3Bfbad19c7D455EB7976DCe51180141  to the chainlog
        // Note: skipped on mainnet as instructed

        // Goerli - Call <conduit>.rely(MCD_ESM) to allow ESM module to deny the pause proxy in SwapInputConduit contracts
        // Note: skipped on mainnet as instructed

        // Note: bump chainlog version, due to the added key
        DssExecLib.setChangelogVersion("1.17.2");

        // ---------- AVC members compensation Q4 2023 ----------
        // Forum: https://forum.makerdao.com/t/avc-member-participation-rewards-q4-2023/23458

        // IamMeeoh - 0x47f7A5d8D27f259582097E1eE59a07a816982AE9 - 20.85 MKR
        MKR.transfer(IAMMEEOH, 20.85 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // DAI-Vinci - 0x9ee47F0f82F1A6F45C4E1D25Ce95C321D8C8356a - 20.85 MKR
        MKR.transfer(DAI_VINCI, 20.85 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // opensky - 0xf44f97f4113759E0a57756bE49C0655d490Cf19F - 20.85 MKR
        MKR.transfer(OPENSKY_2, 20.85 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // ACRE DAOs - 0xBF9226345F601150F64Ea4fEaAE7E40530763cbd - 20.85 MKR
        MKR.transfer(ACREDAOS, 20.85 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // fhomoney.eth - 0xdbD5651F71ce83d1f0eD275aC456241890a53C74 - 20.85 MKR
        MKR.transfer(FHOMONEYETH, 20.85 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Res - 0x8c5c8d76372954922400e4654AF7694e158AB784 - 20.85 MKR
        MKR.transfer(RES, 20.85 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Harmony - 0xE20A2e231215e9b7Aa308463F1A7490b2ECE55D3 - 20.85 MKR
        MKR.transfer(HARMONY_2, 20.85 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Libertas - 0xE1eBfFa01883EF2b4A9f59b587fFf1a5B44dbb2f - 20.85 MKR
        MKR.transfer(LIBERTAS, 20.85 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // seedlatam.eth - 0x0087a081a9b430fd8f688c6ac5dd24421bfb060d - 20.85 MKR
        MKR.transfer(SEEDLATAMETH, 20.85 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // 0xRoot - 0xC74392777443a11Dc26Ce8A3D934370514F38A91 - 20.85 MKR
        MKR.transfer(ROOT, 20.85 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // ---------- Trigger Spark Proxy Spell ----------
        // Forum: https://forum.makerdao.com/t/jan-10-2024-proposed-changes-to-sparklend-for-upcoming-spell/23389
        // Poll: https://vote.makerdao.com/polling/Qmc3NjZA
        // Poll: https://vote.makerdao.com/polling/QmNrXB9P
        // Poll: https://vote.makerdao.com/polling/QmTauEqL
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-8/23445

        // Activate Spark Proxy Spell - 0xa3836fEF1D314d4c081C2707a7664c3375F29b61
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
