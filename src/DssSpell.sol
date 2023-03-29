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


interface GemLike {
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface RwaLiquidationLike {
    function ilks(bytes32) external view returns (string memory, address, uint48, uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
    function bump(bytes32 ilk, uint256 val) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/7d2ba4cf5c3d47e321bdc0d9dc521a0663bf046a/governance/votes/Executive%20vote%20-%20March%2029%2C%202023.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-03-29 MakerDAO Executive Spell | Hash: 0xcab66000cc34553a71300a97f7809bde72c2fbf964fc6a071e4d67058a8e1a3f";

    // Turn office hours off
    function officeHours() public pure override returns (bool) {
        return false;
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

    uint256 internal constant MILLION = 10 ** 6;
    uint256 internal constant BILLION = 10 ** 9;
    
    uint256 internal constant WAD     = 10 ** 18;

    uint256 internal constant PSM_ZERO_BASIS_POINTS = 0;
    uint256 internal constant PSM_ONE_BASIS_POINT   = 1 * WAD / 10000;

    address internal immutable MIP21_LIQUIDATION_ORACLE = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");
    address internal immutable MCD_PSM_USDC_A           = DssExecLib.getChangelogAddress("MCD_PSM_USDC_A");
    address internal immutable MCD_PSM_GUSD_A           = DssExecLib.getChangelogAddress("MCD_PSM_GUSD_A");
    address internal immutable MCD_PSM_PAX_A            = DssExecLib.getChangelogAddress("MCD_PSM_PAX_A");

    GemLike  internal immutable MKR                     = GemLike(DssExecLib.mkr());

    address constant internal LBSBLOCKCHAIN_WALLET      = 0xB83b3e9C8E3393889Afb272D354A7a3Bd1Fbcf5C;
    address constant internal CONSENSYS_WALLET          = 0xE78658A8acfE982Fde841abb008e57e6545e38b3;
    address constant internal SES_WALLET                = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;
    address constant internal CES_WALLET                = 0x25307aB59Cd5d8b4E2C01218262Ddf6a89Ff86da;
    address constant internal PHOENIX_LABS_WALLET       = 0xD9847E6b1314f0327F320E43B51ca0AaAD6FF509;
    
    // Monetalis Update - Excess Funds Declaration
    // Poll:  https://vote.makerdao.com/polling/QmfZ2nxw#poll-details
    // Forum: https://forum.makerdao.com/t/request-to-poll-return-excess-mip65-funds-to-surplus-buffer/20115
    string constant public MIP65 = "Qmf7oGxgVoGKMGkzPi2T6nBSTLgrU5C7jmNqaefjJ52Zup";

    function actions() public override {

        // Uncleared Delegate Compensation
        // Poll:  https://vote.makerdao.com/polling/Qmd2W3Q4#poll-details
        // Forum: https://forum.makerdao.com/t/mip4c2-sp29-amend-mip61-to-tighten-up-recognized-delegate-participation-metrics/18696

        // London Business School Blockchain - 3126 DAI - 0xB83b3e9C8E3393889Afb272D354A7a3Bd1Fbcf5C
        DssExecLib.sendPaymentFromSurplusBuffer(LBSBLOCKCHAIN_WALLET,   3_126);
        // ConsenSys                         -  181 DAI - 0xE78658A8acfE982Fde841abb008e57e6545e38b3
        DssExecLib.sendPaymentFromSurplusBuffer(CONSENSYS_WALLET,         181);


        // SES-001 MKR Transfer
        // Poll:  https://vote.makerdao.com/polling/QmSmhV7z#poll-details
        // Forum: https://forum.makerdao.com/t/mip40c3-sp17-sustainable-ecosystem-scaling-core-unit-mkr-budget-ses-001/8043
        
        MKR.transfer(SES_WALLET, 229.78 ether);  // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // CES-001 MKR Transfer
        // Poll:  https://vote.makerdao.com/polling/QmbNVQ1E#poll-details
        // Forum: https://forum.makerdao.com/t/request-to-poll-one-time-mkr-distribution-to-correct-ces-001-incentive-program-shortfall/19326

        MKR.transfer(CES_WALLET, 77.34 ether);  // NOTE: 'ether' is a keyword helper, only MKR is transferred here


        // Phoenix Labs SPF DAI Funding (MAINNET SPELL ONLY)
        // Poll:  https://vote.makerdao.com/polling/QmYBegVf#poll-details
        // Forum: https://forum.makerdao.com/t/mip55c3-sp15-phoenix-labs-initial-funding-spf/19733

        DssExecLib.sendPaymentFromSurplusBuffer(PHOENIX_LABS_WALLET, 50_000);


        // RETH-A Dust Adjustment from 15,000 DAI to 7,500 DAI
        // Poll:  https://vote.makerdao.com/polling/QmcLGa49#poll-details
        // Forum: https://forum.makerdao.com/t/adjusting-reth-a-dust-parameter-march-2023/20021

        DssExecLib.setIlkMinVaultAmount("RETH-A", 7_500);


        // Monetalis Update - Remove DC-IAM from RWA-007
        // Poll:  https://vote.makerdao.com/polling/QmRJSSGW#poll-details
        // Forum: https://forum.makerdao.com/t/request-to-poll-increase-debt-ceiling-for-mip65-by-750m-to-1-250m/20119
        
        DssExecLib.removeIlkFromAutoLine("RWA007-A");

        // Monetalis Update - Increase the MIP65 (RWA007-A) Debt Ceiling by 750M DAI from 500M DAI to 1,250M DAI
        // Poll:  https://vote.makerdao.com/polling/QmNTSr9j#poll-details
        // Forum: https://forum.makerdao.com/t/request-to-poll-increase-debt-ceiling-for-mip65-by-750m-to-1-250m/20119

        // Increase RWA007-A line by 750M DAI from 500M DAI to 1,250M DAI
        DssExecLib.increaseIlkDebtCeiling(
            "RWA007-A", 
            750 * MILLION,  // DC to 1,250M less existing 500M
            true            // Increase global Line
        );

        // Bump MIP21 Oracle's `val` to 1,250M as WAD (No need to calculate anything since the rate is 0%)
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).bump(
            "RWA007-A",
             1_250 * MILLION * WAD
        );

        // Update the RWA007-A `spot` value in Vat
        DssExecLib.updateCollateralPrice("RWA007-A");

        // PSM Parameter Normalization
        // Poll:  https://vote.makerdao.com/polling/QmQ1fYm3#poll-detail
        // Forum: https://forum.makerdao.com/t/signal-request-set-psm-fees-to-0/10894

        //PSM-USDC-A
        //Reduce the Fee In (tin) by 1% from 1% to 0%.
        DssExecLib.setValue(MCD_PSM_USDC_A, "tin", PSM_ZERO_BASIS_POINTS);
        //Increase the Target Available Debt (gap) by 150 million DAI from 250 million DAI to 400 million DAI.
        DssExecLib.setIlkAutoLineParameters("PSM-USDC-A", 10 * BILLION, 400 * MILLION, 24 hours);

        // PSM-GUSD-A
        // Reduce the Fee In (tin) by 0.1% from 0.1% to 0%.
        DssExecLib.setValue(MCD_PSM_GUSD_A, "tin", PSM_ZERO_BASIS_POINTS);
        // Increase the Fee Out (tout) by 0.01% from 0% to 0.01%.
        DssExecLib.setValue(MCD_PSM_GUSD_A, "tout", PSM_ONE_BASIS_POINT);
        // Increase the Target Available Debt (gap) by 40 million DAI from 10 million DAI to 50 million DAI.
        DssExecLib.setIlkAutoLineParameters("PSM-GUSD-A", 500 * MILLION, 50 * MILLION, 24 hours);

        // PSM-PAX-A
        // Reduce the Fee Out (tout) by 1% from 1% to 0%.
        DssExecLib.setValue(MCD_PSM_PAX_A, "tout", PSM_ZERO_BASIS_POINTS);
        // Reduce the Target Available Debt (gap) by 200 million DAI from 250 million DAI to 50 million DAI.
        // Reduce the Maximum Debt Ceiling (line) by 500 million DAI from 1 billion DAI to 500 million DAI.
        DssExecLib.setIlkAutoLineParameters("PSM-PAX-A", 500 * MILLION, 50 * MILLION, 24 hours);

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
