// SPDX-License-Identifier: GPL-3.0-or-later
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
pragma solidity 0.6.11;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";
import "lib/dss-interfaces/src/dss/OsmAbstract.sol";
import "lib/dss-interfaces/src/dss/PotAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";

interface ChainlogAbstract {
    function removeAddress(bytes32) external;
}

interface LPOracle {
    function orb0() external view returns (address);
    function orb1() external view returns (address);
}

interface GnosisAllowanceModule {
    function executeAllowanceTransfer(address safe, address token, address to, uint96 amount, address paymentToken, uint96 payment, address delegate, bytes memory signature) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/00fc3831345790536ad792b29da2c3cb9d6cbad3/governance/votes/Executive%20vote%20-%20February%2019%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-02-19 MakerDAO Executive Spell | Hash: 0xedcf17520223556b12c535abe7dfc8c70f4f98d4423119a05a37b92b18048bca";


    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant ONE_HUNDREDTH_PCT  = 1000000000003170820659990704;
    uint256 constant THREE_PCT          = 1000000000937303470807876289;
    uint256 constant FOUR_PCT           = 1000000001243680656318820312;

    uint256 constant WAD        = 10**18;
    uint256 constant RAD        = 10**45;
    uint256 constant MILLION    = 10**6;

    address constant UNIV2WBTCDAI_GEM   = 0x231B7589426Ffe1b75405526fC32aC09D44364c4;
    address constant UNIV2WBTCDAI_JOIN  = 0xD40798267795Cbf3aeEA8E9F8DCbdBA9b5281fcC;
    address constant UNIV2WBTCDAI_FLIP  = 0x172200d12D09C2698Dd918d347155fE6692f5662;
    address constant UNIV2WBTCDAI_PIP   = 0x5FB5a346347ACf4FCD3AAb28f5eE518785FB0AD0;

    address constant UNIV2AAVEETH_GEM   = 0xDFC14d2Af169B0D36C4EFF567Ada9b2E0CAE044f;
    address constant UNIV2AAVEETH_JOIN  = 0x42AFd448Df7d96291551f1eFE1A590101afB1DfF;
    address constant UNIV2AAVEETH_FLIP  = 0x20D298ca96bf8c2000203B911908DbDc1a8Bac58;
    address constant UNIV2AAVEETH_PIP   = 0x8D34DC2c33A6386E96cA562D8478Eaf82305b81a;

    function actions() public override {
        // Increase ETH-A Maximum Debt Ceiling
        DssExecLib.setIlkAutoLineDebtCeiling("ETH-A", 2_500 * MILLION);

        // Set Debt Ceiling Instant Access Module Parameters For Multiple Vault Types
        DssExecLib.setIlkAutoLineParameters("LRC-A", 10 * MILLION, 2 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("BAT-A", 3 * MILLION, 1 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("BAL-A", 5 * MILLION, 1 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("MANA-A", 2 * MILLION, 500_000, 12 hours);
        DssExecLib.setIlkAutoLineParameters("ZRX-A", 5 * MILLION, 1 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("KNC-A", 5 * MILLION, 1 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("RENBTC-A", 2 * MILLION, 500_000, 12 hours);

        // Increase System Surplus Buffer
        DssExecLib.setSurplusBuffer(30 * MILLION);

        // Onboard UNIV2WBTCDAI-A
        DssExecLib.addReaderToMedianWhitelist(
            LPOracle(UNIV2WBTCDAI_PIP).orb0(),
            UNIV2WBTCDAI_PIP
        );
        CollateralOpts memory UNIV2WBTCDAI_A = CollateralOpts({
            ilk: "UNIV2WBTCDAI-A",
            gem: UNIV2WBTCDAI_GEM,
            join: UNIV2WBTCDAI_JOIN,
            flip: UNIV2WBTCDAI_FLIP,
            pip: UNIV2WBTCDAI_PIP,
            isLiquidatable: true,
            isOSM: true,
            whitelistOSM: false,
            ilkDebtCeiling: 3 * MILLION,
            minVaultAmount: 2000,
            maxLiquidationAmount: 50000,
            liquidationPenalty: 1300,
            ilkStabilityFee: THREE_PCT,
            bidIncrease: 300,
            bidDuration: 6 hours,
            auctionDuration: 6 hours,
            liquidationRatio: 12500
        });
        addNewCollateral(UNIV2WBTCDAI_A);
        DssExecLib.setChangelogAddress("UNIV2WBTCDAI",             UNIV2WBTCDAI_GEM);
        DssExecLib.setChangelogAddress("MCD_JOIN_UNIV2WBTCDAI_A",  UNIV2WBTCDAI_JOIN);
        DssExecLib.setChangelogAddress("MCD_FLIP_UNIV2WBTCDAI_A",  UNIV2WBTCDAI_FLIP);
        DssExecLib.setChangelogAddress("PIP_UNIV2WBTCDAI",         UNIV2WBTCDAI_PIP);

        // Onboard UNIV2AAVEETH-A
        DssExecLib.addReaderToMedianWhitelist(
            LPOracle(UNIV2AAVEETH_PIP).orb0(),
            UNIV2AAVEETH_PIP
        );
        DssExecLib.addReaderToMedianWhitelist(
            LPOracle(UNIV2AAVEETH_PIP).orb1(),
            UNIV2AAVEETH_PIP
        );
        CollateralOpts memory UNIV2AAVEETH_A = CollateralOpts({
            ilk: "UNIV2AAVEETH-A",
            gem: UNIV2AAVEETH_GEM,
            join: UNIV2AAVEETH_JOIN,
            flip: UNIV2AAVEETH_FLIP,
            pip: UNIV2AAVEETH_PIP,
            isLiquidatable: true,
            isOSM: true,
            whitelistOSM: false,
            ilkDebtCeiling: 3 * MILLION,
            minVaultAmount: 2000,
            maxLiquidationAmount: 50000,
            liquidationPenalty: 1300,
            ilkStabilityFee: FOUR_PCT,
            bidIncrease: 300,
            bidDuration: 6 hours,
            auctionDuration: 6 hours,
            liquidationRatio: 16500
        });
        addNewCollateral(UNIV2AAVEETH_A);
        DssExecLib.setChangelogAddress("UNIV2AAVEETH",             UNIV2AAVEETH_GEM);
        DssExecLib.setChangelogAddress("MCD_JOIN_UNIV2AAVEETH_A",  UNIV2AAVEETH_JOIN);
        DssExecLib.setChangelogAddress("MCD_FLIP_UNIV2AAVEETH_A",  UNIV2AAVEETH_FLIP);
        DssExecLib.setChangelogAddress("PIP_UNIV2AAVEETH",         UNIV2AAVEETH_PIP);

        // Dai Savings Rate Adjustment
        PotAbstract(DssExecLib.pot()).drip();
        DssExecLib.setDSR(ONE_HUNDREDTH_PCT);

        // Remove Permissions for Liquidations Circuit Breaker
        address flipperMom = DssExecLib.flipperMom();
        DssExecLib.deauthorize(DssExecLib.flip("PSM-USDC-A"), flipperMom);
        DssExecLib.deauthorize(DssExecLib.flip("UNIV2DAIUSDC-A"), flipperMom);

        // Fix for Line != sum lines rounding error issue (0.602857457497899800874246318932698818152722680 DAI)
        VatAbstract vat = VatAbstract(DssExecLib.vat());
        vat.file("Line", vat.Line() + 602857457497899800874246318932698818152722680);

        // bump Changelog version
        DssExecLib.setChangelogVersion("1.2.7");
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}
