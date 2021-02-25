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
        "2021-02-26 MakerDAO Executive Spell | Hash: TODO";


    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant FOUR_PCT           = 1000000001243680656318820312;
    uint256 constant FIVE_PT_FIVE_PCT   = 1000000001697766583380253701;
    uint256 constant NINE_PCT           = 1000000002732676825177582095;

    uint256 constant WAD        = 10**18;
    uint256 constant RAD        = 10**45;
    uint256 constant MILLION    = 10**6;

    address constant UNIV2DAIUSDT_GEM   = 0xb20bd5d04be54f870d5c0d3ca85d82b34b836405;
    address constant UNIV2DAIUSDT_JOIN  = 0xAf034D882169328CAf43b823a4083dABC7EEE0F4;
    address constant UNIV2DAIUSDT_FLIP  = 0xd32f8b8adbe331ec0cfada9cfdbc537619622cfe;
    address constant UNIV2DAIUSDT_PIP   = 0x0;

    function actions() public override {
        // Rates Proposal - February 22, 2021
        DssExecLib.setIlkStabilityFee("ETH-A", FIVE_PT_FIVE_PCT);
        DssExecLib.setIlkStabilityFee("ETH-B", NINE_PCT);

        // Onboard UNIV2DAIUSDT-A
        DssExecLib.addReaderToMedianWhitelist(
            LPOracle(UNIV2DAIUSDT_PIP).orb1(),
            UNIV2DAIUSDT_PIP
        );
        CollateralOpts memory UNIV2DAIUSDT_A = CollateralOpts({
            ilk: "UNIV2DAIUSDT-A",
            gem: UNIV2DAIUSDT_GEM,
            join: UNIV2DAIUSDT_JOIN,
            flip: UNIV2DAIUSDT_FLIP,
            pip: UNIV2DAIUSDT_PIP,
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
            liquidationRatio: 12500
        });
        addNewCollateral(UNIV2DAIUSDT_A);
        DssExecLib.setChangelogAddress("UNIV2DAIUSDT",             UNIV2DAIUSDT_GEM);
        DssExecLib.setChangelogAddress("MCD_JOIN_UNIV2DAIUSDT_A",  UNIV2DAIUSDT_JOIN);
        DssExecLib.setChangelogAddress("MCD_FLIP_UNIV2DAIUSDT_A",  UNIV2DAIUSDT_FLIP);
        DssExecLib.setChangelogAddress("PIP_UNIV2DAIUSDT",         UNIV2DAIUSDT_PIP);

        // Lower PSM-USDC-A Toll Out
        DssExecLib.setContract(DssExecLib.getChangelogAddress("MCD_PSM_USDC_A"), "tout", 4 * WAD / 1000);

        // bump Changelog version
        DssExecLib.setChangelogVersion("1.2.8");
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}
